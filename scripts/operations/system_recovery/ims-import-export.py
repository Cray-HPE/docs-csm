#! /usr/bin/env python3
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

import argparse
import json
import logging
import os
import subprocess
import sys
import tempfile
from os import path
from urllib.parse import urlparse

LOGGER = logging.getLogger(__name__)
ch = logging.StreamHandler()
ch.setLevel(logging.ERROR)
LOGGER.addHandler(ch)


def create_parser(program_name):
    """ Creates the parent parser and adds the subparsers """
    parser = argparse.ArgumentParser(prog=program_name)

    parser.add_argument(
        'import_export_root',
        nargs='?',
        default=path.join(os.getcwd(), 'ims-import-export-data'),
        help='Location to import/export IMS data from/to'
    )

    parser.add_argument(
        '-l', '--log-level', type=str, default="INFO",
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
        help='Set the logging level'
    )

    parser.add_argument(
        '--include-deleted',
        action='store_true',
        help="Include deleted IMS recipe and image records"
    )

    parser.add_argument(
        '--include-linked-artifacts',
        action='store_true',
        help="Include linked recipe and image artifacts stored in S3."
    )

    import_export_action = parser.add_mutually_exclusive_group(required=True)
    import_export_action.add_argument('-e', '--export', dest="action", action="store_const", const="export")
    import_export_action.add_argument('-i', '--import', dest="action", action="store_const", const="import")
    return parser


class ImsImportExportBaseError(Exception):
    pass


class ImsImportExportRecoverableError(ImsImportExportBaseError):
    pass


class ImsImportExportNonrecoverableError(ImsImportExportBaseError):
    pass


class S3Url:
    """
    https://stackoverflow.com/questions/42641315/s3-urls-get-bucket-name-and-path/42641363
    """

    def __init__(self, url):
        self._parsed = urlparse(url, allow_fragments=False)

    @property
    def bucket(self):
        """ return the S3 bucket name """
        return self._parsed.netloc

    @property
    def key(self):
        """ return the S3 key name """
        if self._parsed.query:  # pylint: disable=no-else-return
            return self._parsed.path.lstrip('/') + '?' + self._parsed.query
        else:
            return self._parsed.path.lstrip('/')

    @property
    def url(self):
        """ return the combined S3 url """
        return self._parsed.geturl()

    @property
    def filename(self):
        """ return just the filename portion of the key """
        return self._parsed.path.split('/')[-1]

    def __repr__(self):
        return self._parsed.geturl()


def safe_list_get(lst, idx, default):
    """
    https://stackoverflow.com/questions/5125619/why-doesnt-list-have-safe-get-method-like-dictionary
    """
    try:
        return lst[idx]
    except KeyError:
        return default


def export_ims_recipe(recipe, recipes_dir, args):
    recipe_dir = path.join(recipes_dir, recipe['id'])

    def _export_s3_recipe_artifact():
        os.mkdir(recipe_dir)
        s3url = S3Url(recipe['link']['path'])
        local_artifact_path = path.join(recipe_dir, s3url.filename)

        command = ['cray', 'artifacts', 'get', s3url.bucket, s3url.key, local_artifact_path]
        LOGGER.debug(' '.join(command))
        result = subprocess.check_output(command)
        LOGGER.debug(result)

        return {
            'linked_artifacts': {
                'recipe_archive': local_artifact_path[len(args.import_export_root) + 1:],
            }
        }

    return_value = recipe
    LOGGER.info(f'Exporting IMS recipe id {recipe["id"]}')
    if args.include_linked_artifacts and recipe['link']['type'] and recipe['link']['path']:
        return_value.update(
            {
                's3': _export_s3_recipe_artifact
            }.get(recipe['link']['type'])()
        )
    return return_value


def export_ims_recipes(args):
    for deleted in (False, True):

        if deleted and not args.include_deleted:
            continue

        recipes_path = args.import_export_root
        if deleted:
            recipes_path = path.join(recipes_path, 'deleted')
        recipes_path = path.join(recipes_path, 'recipes')

        if args.include_linked_artifacts:
            os.makedirs(recipes_path)

        LOGGER.info(f'Exporting {"recipes" if not deleted else "deleted recipes"}')

        command = ['cray', 'ims']
        if deleted:
            command.append('deleted')
        command.extend(['recipes', 'list', '--format', 'json'])

        export_data = []
        LOGGER.debug(' '.join(command))
        recipes = json.loads(subprocess.check_output(command))
        LOGGER.debug(recipes)

        for recipe in recipes:
            export_data.append(export_ims_recipe(recipe, recipes_path, args))

        export_file = 'recipes.json' if not deleted else 'deleted_recipes.json'
        with open(path.join(args.import_export_root, export_file), 'w') as outfile:
            json.dump(
                {
                    'version': '1.0',
                    'records': export_data
                },
                outfile)


def export_ims_image(image, recipes_dir, args):
    image_dir = path.join(recipes_dir, image['id'])

    def _export_linked_image_artifact(artifact):
        s3url = S3Url(artifact['link']['path'])
        local_artifact_path = path.join(image_dir, s3url.filename)
        command = ['cray', 'artifacts', 'get', s3url.bucket, s3url.key, local_artifact_path]

        LOGGER.debug(' '.join(command))
        result = subprocess.check_output(command)
        LOGGER.debug(result)

        return {
            "md5": safe_list_get(artifact, 'md5', ''),
            "type": artifact['type'],
            'path': local_artifact_path[len(args.import_export_root) + 1:],
        }

    def _export_linked_image_artifacts(manifest_json):
        linked_artifacts = []
        for artifact in manifest_json['artifacts']:
            linked_artifacts.append(_export_linked_image_artifact(artifact))
        return linked_artifacts

    def _export_s3_image_artifacts():
        os.mkdir(image_dir)
        s3url = S3Url(image['link']['path'])
        local_artifact_path = path.join(image_dir, s3url.filename)
        command = ['cray', 'artifacts', 'get', s3url.bucket, s3url.key, local_artifact_path]
        LOGGER.debug(' '.join(command))
        result = subprocess.check_output(command)
        LOGGER.debug(result)

        # export artifacts linked in the manifest json
        with open(local_artifact_path) as manifest_file:
            manifest_json = json.load(manifest_file)
            image_artifacts = {
                "1.0": _export_linked_image_artifacts,
            }.get(manifest_json['version'])(manifest_json)

            return {
                'linked_artifacts': {
                    'manifest_json': local_artifact_path[len(args.import_export_root) + 1:],
                    'image_artifacts': image_artifacts
                }
            }

    return_value = image
    LOGGER.info(f'Exporting IMS image id {image["id"]}')
    if args.include_linked_artifacts and image['link']['type'] and image['link']['path']:
        return_value.update(
            {
                's3': _export_s3_image_artifacts
            }.get(image['link']['type'])()
        )
    return return_value


def export_ims_images(args):
    for deleted in (False, True):

        if deleted and not args.include_deleted:
            continue

        images_path = args.import_export_root
        if deleted:
            images_path = path.join(images_path, 'deleted')
        images_path = path.join(images_path, 'images')

        if args.include_linked_artifacts:
            os.makedirs(images_path)

        LOGGER.info(f'Exporting {"images" if not deleted else "deleted images"}')

        command = ['cray', 'ims']
        if deleted:
            command.append('deleted')
        command.extend(['images', 'list', '--format', 'json'])

        export_data = []
        LOGGER.debug(' '.join(command))
        images = json.loads(subprocess.check_output(command))
        LOGGER.debug(images)

        for image in images:
            export_data.append(export_ims_image(image, images_path, args))

        export_file = 'images.json' if not deleted else 'deleted_images.json'
        with open(path.join(args.import_export_root, export_file), 'w') as outfile:
            json.dump(
                {
                    'version': '1.0',
                    'records': export_data
                },
                outfile)


def export_ims_artifacts(args):
    # TODO Verify path doesn't exist
    try:
        os.makedirs(args.import_export_root)

        export_ims_recipes(args)
        export_ims_images(args)
    except ImsImportExportBaseError as ims_exc:
        LOGGER.warning('Error exporting IMS data', exc_info=ims_exc)
        return False

    return True


def artifact_exists(link, md5=''):
    def _check_s3_artifact():
        s3url = S3Url(link['path'])
        command = ['cray', 'artifacts', 'describe', s3url.bucket, s3url.key, '--format', 'json']

        try:
            LOGGER.info(f'Checking if s3 artifact {link["path"]} exists')
            LOGGER.debug(' '.join(command))
            artifact_info = json.loads(subprocess.check_output(command))
            LOGGER.debug(artifact_info)
            LOGGER.info(f'The artifact {link["path"]} exists in S3')

            if md5:
                try:
                    if md5 != artifact_info['artifact']['Metadata']['md5sum']:
                        LOGGER.warning('MD5 sums do not match for the artifact {link["path"]}')
                        return False
                except KeyError:
                    pass

        except subprocess.CalledProcessError as err:
            LOGGER.warning(f'The artifact {link["path"]} does not exist in S3', exc_info=err)
            return False

        return True

    if link['type'] and link['path']:
        return {
            's3': _check_s3_artifact
        }.get(link['type'])()

    return True


def artifact_upload(link_type, link_path, artifact_path):
    def _upload_s3_artifact():
        s3url = S3Url(link_path)

        try:
            # Upload the artifact to S3
            command = ['cray', 'artifacts', 'create', s3url.bucket, s3url.key, artifact_path, '--format', 'json']
            try:
                LOGGER.debug(' '.join(command))
                result = subprocess.check_output(command)
                LOGGER.debug(result)
            except subprocess.CalledProcessError:
                LOGGER.warning(f'Failed to upload artifact {link_path} to s3')
                raise

            # get the etag value for the artifact
            command = ['cray', 'artifacts', 'describe', s3url.bucket, s3url.key, '--format', 'json']
            try:
                LOGGER.debug(' '.join(command))
                result = json.loads(subprocess.check_output(command))
                LOGGER.debug(result)
                etag = result['artifact']['ETag'].strip('\"')
            except subprocess.CalledProcessError:
                LOGGER.warning(f'Failed to get etag for artifact {link_path} to s3')
                raise

        except subprocess.CalledProcessError:
            # TODO Fix
            return False, ""

        return True, etag

    return {
        's3': _upload_s3_artifact
    }.get(link_type)()


def recipe_exists(recipe):
    command = ['cray', 'ims', 'recipes', 'describe', recipe['id'], '--format', 'json']

    try:
        LOGGER.info(f'Checking if IMS recipe ID {recipe["id"]} exists in IMS')
        LOGGER.debug(' '.join(command))
        result = json.loads(subprocess.check_output(command))
        LOGGER.debug(result)
    except subprocess.CalledProcessError:
        LOGGER.info(f'IMS recipe {recipe["id"]} was not found in IMS.')
        return False

    return artifact_exists(recipe['link'])


def import_ims_recipe(recipe, recipes_path):
    try:
        # Check if the recipe is in IMS. If it is missing or doesn't match,
        # then let's import a new one.
        if not recipe_exists(recipe):

            s3url = S3Url(recipe['link']['path'])
            recipe_path = path.join(recipes_path, recipe['id'])

            # verify if we can find the recipe archive to upload
            if not path.isfile(path.join(recipe_path, s3url.filename)):
                raise (ImsImportExportRecoverableError(
                    f'Recipe archive not found for IMS recipe {recipe["id"]}. Cannot import recipe.'
                ))

            # create a new ims recipe record
            command = [
                'cray',
                'ims',
                'recipes',
                'create',
                '--name', recipe['name'],
                '--recipe-type', recipe['recipe_type'],
                '--linux-distribution', recipe['linux_distribution'],
                '--format', 'json'
            ]
            LOGGER.debug(' '.join(command))
            new_recipe = json.loads(subprocess.check_output(command))
            LOGGER.debug(new_recipe)

            # upload recipe archive
            new_recipe_link_path = \
                f'{recipe["link"]["type"]}://{s3url.bucket}/recipes/{new_recipe["id"]}/{s3url.filename}'
            success, new_recipe_link_etag = artifact_upload(
                recipe['link']['type'],
                new_recipe_link_path,
                path.join(recipe_path, s3url.filename)
            )

            # patch recipe record
            command = [
                'cray',
                'ims',
                'recipes',
                'update',
                new_recipe['id'],
                '--link-type', recipe['link']['type'],
                '--link-path', new_recipe_link_path,
                '--link-etag', new_recipe_link_etag,
                '--format', 'json'
            ]
            LOGGER.debug(' '.join(command))
            result = json.loads(subprocess.check_output(command))
            LOGGER.debug(result)

            return new_recipe['id']

    except ImsImportExportRecoverableError:
        # TODO
        pass
    except subprocess.CalledProcessError as call_proc_exc:
        LOGGER.warning(f'An error was encountered while importing IMS image {recipe["id"]}.', exc_info=call_proc_exc)

    return None


def import_ims_recipes(args):
    def _import_v1_0_recipes(recipes):

        for recipe in recipes:
            new_recipe_id = import_ims_recipe(recipe, recipes_path)
            if new_recipe_id and new_recipe_id != recipe['id']:
                imported_recipes[recipe['id']] = new_recipe_id

    imported_recipes = {}
    LOGGER.info(f'Importing recipes')
    recipes_path = path.join(args.import_export_root, 'recipes')
    with open(path.join(args.import_export_root, 'recipes.json')) as infile:
        import_json = json.load(infile)
        {
            '1.0': _import_v1_0_recipes
        }.get(import_json['version'])(import_json['records'])

    return imported_recipes


def image_exists(image):
    command = ['cray', 'ims', 'images', 'describe', image['id'], '--format', 'json']

    try:
        LOGGER.info(f'Checking if IMS image ID {image["id"]} exists in IMS')
        LOGGER.debug(' '.join(command))
        result = json.loads(subprocess.check_output(command))
        LOGGER.debug(result)
    except subprocess.CalledProcessError:
        LOGGER.info(f'IMS image {image["id"]} was not found in IMS.')
        return False

    # TODO Don't just check image manifest, check for linked artifacts too!
    return artifact_exists(image['link'])


def import_ims_image(image, images_path):
    def _upload_1_0_linked_artifacts(artifacts):
        ret_value = []
        for artifact in artifacts:
            artifact_url = S3Url(artifact['link']['path'])
            artifact_file = path.join(images_path, image['id'], artifact_url.filename)
            if path.isfile(artifact_file):
                new_artifact_link_path = \
                    f'{image["link"]["type"]}://{artifact_url.bucket}/{new_image["id"]}/{artifact_url.filename}'

                _, new_artifact_link_etag = artifact_upload(image['link']['type'],
                                                            new_artifact_link_path,
                                                            artifact_file)

                ret_value.append({
                    'md5': artifact['md5'],
                    'type': artifact['type'],
                    'link': {
                        'etag': new_artifact_link_etag,
                        'path': new_artifact_link_path,
                        'type': artifact['link']['type']
                    }
                })
        return ret_value

    try:
        # Check if the image is in IMS. If it is missing or doesn't match,
        # then let's import a new one.
        if not image_exists(image):

            s3url = S3Url(image['link']['path'])
            image_path = path.join(images_path, image['id'])

            # verify if we can find the recipe archive to upload
            if not path.isfile(path.join(image_path, s3url.filename)):
                raise (ImsImportExportRecoverableError(
                    f'Image manifest.json not found for IMS image {image["id"]}. Cannot import image.'
                ))

            # create a new ims image record
            command = [
                'cray',
                'ims',
                'images',
                'create',
                '--name', image['name'],
                '--format', 'json'
            ]
            LOGGER.debug(' '.join(command))
            new_image = json.loads(subprocess.check_output(command))
            LOGGER.debug(new_image)

            # TODO Read manifest.json and upload linked artifacts
            with open(path.join(image_path, s3url.filename)) as manifest_fp:
                manifest_json = json.load(manifest_fp)
                artifact_manifest = {
                    '1.0': _upload_1_0_linked_artifacts
                }.get(manifest_json['version'])(manifest_json['artifacts'])

            # TODO Generate new manifest.json file
            tmp_manifest_fd, tmp_manifest_path = tempfile.mkstemp()
            try:
                # create a new image manifest.json file
                with open(tmp_manifest_fd, 'w') as tmp:
                    # do stuff with temp file
                    json.dump({
                        'version': manifest_json['version'],
                        'created': manifest_json['created'],
                        'artifacts': artifact_manifest
                    }, tmp)

                new_image_manifest_json_link_path = \
                    f'{image["link"]["type"]}://{s3url.bucket}/{new_image["id"]}/{s3url.filename}'

                # upload image manifest.json
                success, new_image_manifest_json_link_etag = artifact_upload(
                    image['link']['type'], new_image_manifest_json_link_path,
                    tmp_manifest_path
                )

                # patch image record
                command = [
                    'cray',
                    'ims',
                    'images',
                    'update',
                    new_image['id'],
                    '--link-type', image['link']['type'],
                    '--link-path', new_image_manifest_json_link_path,
                    '--link-etag', new_image_manifest_json_link_etag,
                    '--format', 'json'
                ]
                LOGGER.debug(' '.join(command))
                result = json.loads(subprocess.check_output(command))
                LOGGER.debug(result)

                return new_image['id']
            finally:
                os.remove(tmp_manifest_path)

    except ImsImportExportRecoverableError:
        # TODO
        pass
    except subprocess.CalledProcessError as call_proc_exc:
        LOGGER.warning(f'An error was encountered while importing IMS image {image["id"]}.', exc_info=call_proc_exc)

    return None


def import_ims_images(args):
    def _import_v1_0_images(images):
        for image in images:
            new_image_id = import_ims_image(image, images_path)
            if new_image_id and new_image_id != image['id']:
                imported_images[image['id']] = new_image_id

    imported_images = {}
    LOGGER.info(f'Importing images')
    images_path = path.join(args.import_export_root, 'images')
    with open(path.join(args.import_export_root, 'images.json')) as infile:
        import_json = json.load(infile)
        {
            '1.0': _import_v1_0_images
        }.get(import_json['version'])(import_json['records'])

    return imported_images


def import_ims_artifacts(args):
    try:
        recipe_map = import_ims_recipes(args)
        image_map = import_ims_images(args)

        for old_recipe_id, new_recipe_id in recipe_map.items():
            LOGGER.info(f'The IMS recipe {old_recipe_id} was imported as {new_recipe_id}')

        for old_image_id, new_image_id in image_map.items():
            LOGGER.info(f'The IMS image {old_image_id} was imported as {new_image_id}')

    except ImsImportExportBaseError as ims_exc:
        LOGGER.warning('Error importing IMS data', exc_info=ims_exc)
        return False

    return True


def main(program_name, args):
    """ Main function """

    parser = create_parser(program_name)
    args = parser.parse_args(args)
    logging.basicConfig(level=args.log_level)

    result = {
        "import": import_ims_artifacts,
        "export": export_ims_artifacts,
    }.get(args.action)(args)

    LOGGER.info('DONE!')

    return result


if __name__ == "__main__":
    sys.exit(main("ims-import-export", sys.argv[1:]))
