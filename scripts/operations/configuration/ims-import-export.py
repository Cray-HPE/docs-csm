#! /usr/bin/env python3
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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
import datetime
import json
import logging
import os
import subprocess
import sys
import tempfile
import uuid
from os import path
from urllib.parse import urlparse

import update_ims_ids_in_bos
import update_product_catalog_ims_ids

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


def get_timestamp_string():
    return str(datetime.datetime.now().astimezone())


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
    if args.include_linked_artifacts and recipe['link'] and recipe['link']['type'] and recipe['link']['path']:
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
                    'timestamp': get_timestamp_string(),
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
    if args.include_linked_artifacts and image['link'] and image['link']['type'] and image['link']['path']:
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
                    'timestamp': get_timestamp_string(),
                    'version': '1.0',
                    'records': export_data
                },
                outfile)


def export_ims_artifacts(args):
    # TODO Verify path doesn't exist
    try:
        os.makedirs(args.import_export_root)
        LOGGER.info(f'Exporting IMS data to {args.import_export_root}')
        export_ims_recipes(args)
        export_ims_images(args)
        LOGGER.info(f'IMS data exported to {args.import_export_root}')
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

    if link and link['type'] and link['path']:
        return {
            's3': _check_s3_artifact
        }.get(link['type'])()

    return True


def artifact_upload(link_type, link_path, artifact_path):
    LOGGER.debug(
        "Uploading S3 artifact; link_type=%s, link_path=%s, artifact_path=%s",
        link_type, link_path, artifact_path
    )
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

    return True


def patch_record(images_or_recipes, record_id, link_type, link_path, link_etag):
    # patch record
    command = [
        'cray',
        'ims',
        images_or_recipes,
        'update',
        record_id,
        '--format', 'json',
        '--link-type', link_type,
        '--link-path', link_path,
        '--link-etag', link_etag
    ]
    LOGGER.debug(' '.join(command))
    result = json.loads(subprocess.check_output(command))
    LOGGER.debug(result)
    return result


def create_ims_recipe(recipe):
    """
    Creates a new recipe record in IMS.
    Parses the JSON response object from the create request and returns it.
    """
    # create a new ims recipe record
    command = [
        'cray',
        'ims',
        'recipes',
        'create',
        '--format', 'json',
        '--name', recipe['name'],
        '--recipe-type', recipe['recipe_type'],
        '--linux-distribution', recipe['linux_distribution']
    ]
    LOGGER.debug(' '.join(command))
    new_recipe = json.loads(subprocess.check_output(command))
    LOGGER.debug(new_recipe)
    return new_recipe


def import_ims_recipe(recipe, recipes_path):
    """
    Returns (new IMS recipe ID, new recipe S3 etag)
    A None value for either one means that the value did not change
    """
    def _patch_recipe(recipe_id, **kwargs):
        return patch_record("recipes", record_id=recipe_id, link_type=recipe['link']['type'], **kwargs)

    def _recipe_artifact_upload(link_path):
        s3url = S3Url(recipe['link']['path'])
        recipe_path = path.join(recipes_path, recipe['id'])
        artifact_path=path.join(recipe_path, s3url.filename)

        # verify that we can find the recipe archive to upload
        if not path.isfile(path.join(recipe_path, s3url.filename)):
            raise (ImsImportExportRecoverableError(
                f'Recipe archive not found for IMS recipe {recipe["id"]}. Cannot import recipe.'
            ))

        return artifact_upload(
            link_type=recipe['link']['type'],
            link_path=link_path,
            artifact_path=artifact_path
        )

    # There are 4 possible situations:
    # The recipe is both in IMS and S3
    # The recipe is in IMS and not S3
    # The recipe is not in IMS but is in S3
    # The recipe is not in IMS and not in S3
    # The latter two are treated the same way, because if the recipe is not in IMS,
    # it will get a new ID when we add it into IMS, so we will have to upload it to S3
    # under that new ID anyway.

    try:
        recipe_in_ims = recipe_exists(recipe)

        if recipe_in_ims:
            LOGGER.debug("Recipe %s exists in IMS", recipe["id"])
            if artifact_exists(recipe['link']):
                LOGGER.debug("Recipe artifact for %s exists in S3", recipe["id"])
                return None, None
            LOGGER.debug("Recipe artifact for %s does not exist in S3", recipe["id"])

            # Just need to upload it to S3
            success, new_recipe_link_etag = _recipe_artifact_upload(link_path=recipe['link']['path'])

            if not success:
                raise ImsImportExportRecoverableError(f'S3 upload not successful for recipe {recipe["id"]}')

            # Patch record
            _patch_recipe(
                recipe_id=recipe["id"],
                link_path=recipe['link']['path'],
                link_etag=new_recipe_link_etag
            )

            # IMS ID did not change, so we only return the new etag value
            return None, new_recipe_link_etag

        LOGGER.debug("Recipe %s does not exist in IMS", recipe["id"])

        # create a new ims recipe record
        new_recipe = create_ims_recipe(recipe)

        # upload recipe archive, if available
        if not recipe['link']:
            LOGGER.debug("Recipe %s has no link data, so it cannot be uploaded to S3", recipe['id'])
            return new_recipe['id'], None
        if not recipe['link']['type'] or not recipe['link']['path']:
            LOGGER.debug(
                "Recipe %s has missing type (%s) and/or path (%s), so it cannot be uploaded to S3",
                recipe['id'], recipe['link']['type'], recipe['link']['path']
            )
            return new_recipe['id'], None

        s3url = S3Url(recipe['link']['path'])
        new_recipe_link_path = \
            f'{recipe["link"]["type"]}://{s3url.bucket}/recipes/{new_recipe["id"]}/{s3url.filename}'
        success, new_recipe_link_etag = _recipe_artifact_upload(link_path=new_recipe_link_path)

        if not success:
            raise ImsImportExportRecoverableError(f'S3 upload not successful for recipe {new_recipe["id"]}')

        # patch recipe record
        _patch_recipe(
            recipe_id=new_recipe['id'],
            link_path=new_recipe_link_path,
            link_etag=new_recipe_link_etag
        )

        return new_recipe['id'], new_recipe_link_etag

    except ImsImportExportRecoverableError as call_proc_exc:
        LOGGER.error(f'An error was encountered while importing IMS recipe {recipe["id"]}.', exc_info=call_proc_exc)
    except subprocess.CalledProcessError as call_proc_exc:
        LOGGER.warning(f'An error was encountered while importing IMS recipe {recipe["id"]}.', exc_info=call_proc_exc)

    return None, None


def import_ims_recipes(args, etag_map):
    def _import_v1_0_recipes(recipes):
        for recipe in recipes:
            old_recipe_etag = None
            if recipe['link']:
                old_recipe_etag = recipe['link']['etag']
            new_recipe_id, new_recipe_etag = import_ims_recipe(recipe, recipes_path)
            if new_recipe_id and new_recipe_id != recipe['id']:
                imported_recipes[recipe['id']] = new_recipe_id
            if old_recipe_etag and new_recipe_etag and new_recipe_etag != old_recipe_etag:
                etag_map[old_recipe_etag] = new_recipe_etag

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

    return True


def create_ims_image(image):
    """
    Creates a new image record in IMS.
    Parses the JSON response object from the create request and returns it.
    """
    # create a new ims image record
    command = [
        'cray',
        'ims',
        'images',
        'create',
        '--format', 'json',
        '--name', image['name']
    ]
    LOGGER.debug(' '.join(command))
    new_image = json.loads(subprocess.check_output(command))
    LOGGER.debug(new_image)
    return new_image


def import_ims_image(image, images_path, etag_map):
    """
    Returns (new IMS recipe ID, new recipe S3 etag)
    A None value for either one means that the value did not change
    """
    def _patch_image(image_id, **kwargs):
        return patch_record("images", record_id=image_id, link_type=image['link']['type'], **kwargs)

    def _upload_1_0_linked_artifacts(artifacts, image_id):
        ret_value = []
        for artifact in artifacts:
            artifact_url = S3Url(artifact['link']['path'])
            artifact_file = path.join(images_path, image['id'], artifact_url.filename)
            if not path.isfile(artifact_file):
                continue
            artifact_etag = artifact['link']['etag']
            new_artifact_link_path = \
                f'{image["link"]["type"]}://{artifact_url.bucket}/{image_id}/{artifact_url.filename}'

            success, new_artifact_link_etag = artifact_upload(
                link_type=image['link']['type'],
                link_path=new_artifact_link_path,
                artifact_path=artifact_file)

            if not success:
                raise ImsImportExportRecoverableError(f"S3 upload not successful for {new_artifact_link_path}")

            if artifact_etag and new_artifact_link_etag and artifact_etag != new_artifact_link_etag:
                etag_map[artifact_etag] = new_artifact_link_etag

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

    def _upload_artifacts_patch_image(image_id, new_manifest_link_path):
        s3url = S3Url(image['link']['path'])
        image_path = path.join(images_path, image['id'])

        # verify that we can find the archive to upload
        if not path.isfile(path.join(image_path, s3url.filename)):
            raise (ImsImportExportRecoverableError(
                f'Image manifest.json not found for IMS image {image["id"]}. Cannot import image.'
            ))

        manifest_archive_path = path.join(image_path, s3url.filename)

        # Read manifest.json and upload linked artifacts
        with open(manifest_archive_path) as manifest_fp:
            manifest_json = json.load(manifest_fp)
            artifact_manifest = {
                '1.0': _upload_1_0_linked_artifacts
            }.get(manifest_json['version'])(manifest_json['artifacts'], image_id)

        # Generate new manifest.json file
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

            # upload image manifest.json
            success, new_image_manifest_json_link_etag = artifact_upload(
                link_type=image['link']['type'],
                link_path=new_manifest_link_path,
                artifact_path=tmp_manifest_path
            )
        finally:
            os.remove(tmp_manifest_path)

        if not success:
            raise ImsImportExportRecoverableError(f"S3 upload not successful for {new_manifest_link_path}")

        _patch_image(
            image_id=image_id,
            link_path=new_manifest_link_path,
            link_etag=new_image_manifest_json_link_etag
        )
        return new_image_manifest_json_link_etag

    # There are 4 possible situations:
    # The image is both in IMS and S3
    # The image is in IMS and not S3
    # The image is not in IMS but is in S3
    # The image is not in IMS and not in S3
    # The latter two are treated the same way, because if the image is not in IMS,
    # it will get a new ID when we add it into IMS, so we will have to upload it to S3
    # under that new ID anyway.

    try:
        image_in_ims = image_exists(image)

        if image_in_ims:
            LOGGER.debug("Image %s exists in IMS", image["id"])
            # TODO Don't just check image manifest, check for linked artifacts too!
            if artifact_exists(image['link']):
                LOGGER.debug("Image artifact for %s exists in S3", image["id"])
                return None, None
            LOGGER.debug("Image artifact for %s does not exist in S3", image["id"])

            # Just need to upload it to S3
            new_image_manifest_json_link_etag = _upload_artifacts_patch_image(
                image_id=image["id"],
                new_manifest_link_path=image['link']['path']
            )

            # IMS ID did not change, so we only return the new etag value
            return None, new_image_manifest_json_link_etag

        LOGGER.debug("Image %s does not exist in IMS", image["id"])

        # create a new ims image record
        new_image = create_ims_image(image)

        # upload image archive, if available
        if not image['link']:
            LOGGER.debug("Image %s has no link data, so it cannot be uploaded to S3", image['id'])
            return new_image['id'], None
        if not image['link']['type'] or not image['link']['path']:
            LOGGER.debug(
                "Image %s has missing type (%s) and/or path (%s), so it cannot be uploaded to S3",
                image['id'], image['link']['type'], image['link']['path']
            )
            return new_image['id'], None

        s3url = S3Url(image['link']['path'])
        new_image_manifest_json_link_path = \
            f'{image["link"]["type"]}://{s3url.bucket}/{new_image["id"]}/{s3url.filename}'

        new_image_manifest_json_link_etag = _upload_artifacts_patch_image(
            image_id=new_image["id"],
            new_manifest_link_path=new_image_manifest_json_link_path
        )

        return new_image['id'], new_image_manifest_json_link_etag

    except ImsImportExportRecoverableError as call_proc_exc:
        # TODO
        LOGGER.error(f'An error was encountered while importing IMS image {image["id"]}.', exc_info=call_proc_exc)
    except subprocess.CalledProcessError as call_proc_exc:
        LOGGER.warning(f'An error was encountered while importing IMS image {image["id"]}.', exc_info=call_proc_exc)

    return None, None


def import_ims_images(args, etag_map):
    def _import_v1_0_images(images):
        for image in images:
            old_image_etag = None
            if image['link']:
                old_image_etag = image['link']['etag']
            new_image_id, new_image_etag = import_ims_image(image, images_path, etag_map=etag_map)
            if new_image_id and new_image_id != image['id']:
                imported_images[image['id']] = new_image_id
            if old_image_etag and new_image_etag and new_image_etag != old_image_etag:
                etag_map[old_image_etag] = new_image_etag

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
        LOGGER.info(f'Importing IMS data from {args.import_export_root}')
        etag_map = {}
        recipe_map = import_ims_recipes(args, etag_map=etag_map)
        image_map = import_ims_images(args, etag_map=etag_map)

        for old_recipe_id, new_recipe_id in recipe_map.items():
            LOGGER.info(f'The IMS recipe {old_recipe_id} was imported as {new_recipe_id}')

        for old_image_id, new_image_id in image_map.items():
            LOGGER.info(f'The IMS image {old_image_id} was imported as {new_image_id}')

        for old_etag, new_etag in etag_map.items():
            LOGGER.info(f'The S3 artifact with etag {old_etag} was imported with etag {new_etag}')

        # Record mappings of old IMS IDs and S3 etags to new ones
        id_map_file = path.join(os.getcwd(), f'ims-id-maps-post-import-{uuid.uuid4().hex}.json')
        id_map_contents = {
            'etag_map': etag_map,
            'id_maps': {
                "images": image_map,
                "recipes": recipe_map
            },
            'timestamp': get_timestamp_string()
        }
        with open(id_map_file, 'w') as outfile:
            json.dump(id_map_contents, outfile)
        LOGGER.info(f'Recorded mapping from old to new IMS IDs and S3 etags in {id_map_file}')
        LOGGER.info(f'IMS data imported from {args.import_export_root}')

        # If any image or recipe IDs changed, update the product catalog if needed
        if image_map or recipe_map:
            LOGGER.info('Updating IMS IDs in Cray Product Catalog')
            update_product_catalog_ims_ids.update_product_catalog(image_map, recipe_map)

        # If any image IDs or etags changed, update BOS if needed
        if image_map or etag_map:
            LOGGER.info('Updating IMS IDs and etags in BOS')
            update_ims_ids_in_bos.update_bos_from_dict(id_map_contents)

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
