#!/bin/bash
#
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

# For each cronjob based postgresql-db backup:
#   Suspend the cronjob backup
#   Delete existing postgresql-db-backup jobs
#   Delete any existing backup in the postgres-backup s3 bucket
#   Patch the cronjob to use the cray-postgres-db-backup:0.2.3 image
#   Create a manual backup job
#   Wait for the manual backup job to complete
#   Delete the manual backup job (unless backup failed)
#   Resume the cronjon backup
# List all the postgres-backups

postgres_to_backup=""  # default is all opt-in postgres clusters
image_to_patch="artifactory.algol60.net/csm-docker/stable/cray-postgres-db-backup:0.2.3"

while getopts s:i:h stack
do
    case "${stack}" in
          s) postgres_to_backup=$OPTARG;;
          i) image_to_patch=$OPTARG;;
          h) echo "usage: create_new_postgres_backups.sh [-h] [-s <single_cluster>] [-i <image>]"
             echo  -e "\nA tool to recreate opt-in postgres backups using a patched cray-postgres-db-backup image.\n"
             echo "       create_new_postgres_backups.sh                     # Deletes & ReCreates postgres backups for all the opt-in postgres clusters."
             echo "       create_new_postgres_backups.sh -s <single_cluster> # Delete & ReCreate postgres backup for a single opt-in postgres cluster."
             echo "             select from one of: $(kubectl get cronjobs -A | grep postgresql-db-backup | awk '{printf "\n\t\t"$2}') "
             echo "       create_new_postgres_backups.sh -i <image>          # Patches the cray-postgres-db-backup image used to create the new postgres backups."
	     echo "             artifactory.algol60.net/csm-docker/stable/cray-postgres-db-backup:0.2.3 (default)"
             exit 3;;
          \?) echo "usage: create_new_postgres_backups.sh [-h] [-s <single_cluster>] [-i <image>]"
             echo  -e "\nA tool to recreate opt-in postgres backups using a patched cray-postgres-db-backup image.\n"
             echo "       create_new_postgres_backups.sh                     # Deletes & ReCreates postgres backups for all the opt-in postgres clusters."
             echo "       create_new_postgres_backups.sh -s <single_cluster> # Delete & ReCreate postgres backup for a single opt-in postgres cluster."
             echo "             select from one of: $(kubectl get cronjobs -A | grep postgresql-db-backup | awk '{printf "\n\t\t"$2}') "
             echo "       create_new_postgres_backups.sh -i <image>          # Patches the cray-postgres-db-backup image used to create the new postgres backups."
	     echo "             artifactory.algol60.net/csm-docker/stable/cray-postgres-db-backup:0.2.3 (default)"
             exit 3;;
    esac
done

function check_image()
{
    # Does the $image_to_patch tag exist in nexus? If not exit with an error
    image_tag="$(echo $image_to_patch | awk -F: '{ print $2 }')"
    image="$(echo $image_to_patch | awk -F: '{ print $1 }')"
    registry_tag="$(curl -sk https://registry.local/v2/\\"$image\\"/tags/list | jq -r  '.tags[]' | grep $image_tag)"

    if [[ "$image_tag" != "$registry_tag" ]]
    then
        echo "ERROR : The image $image_to_patch does not exist in the nexus registry."
        echo "For non-airgapped system, run the following to load the cray-postgres-db-backup image into the nexus registry and then re-run."
        echo  '    NEXUS_USERNAME="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.username}} | base64 -d)"'
        echo  '    NEXUS_PASSWORD="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.password}} | base64 -d)"'
        echo  "    podman run --rm --network host quay.io/skopeo/stable copy --dest-tls-verify=false --dest-creds \"\${NEXUS_USERNAME}:\${NEXUS_PASSWORD}\" docker://${image}:${image_tag} docker://registry.local/${image}:${image_tag}"
	exit 3
    fi

}

function suspend_backup()
{
    echo -en "    "
    kubectl patch cronjobs ${c_cronjob_name} -n ${c_ns} -p '{"spec":{"suspend":true}}'
}

function resume_backup()
{
    echo -en "    "
    kubectl patch cronjobs ${c_cronjob_name} -n ${c_ns} -p '{"spec":{"suspend":false}}'
}

function create_manual_job()
{
    echo -en "    "
    kubectl create job --from=cronjobs/${c_cronjob_name} -n ${c_ns} "${c_cronjob_name}-manual"
}

function delete_manual_job()
{
    echo -en "    "
    kubectl delete job -n ${c_ns} "${c_cronjob_name}-manual"
}


function wait_for_job()
{
    echo -en "    "
    kubectl -n $c_ns wait --for=condition=complete --timeout=2m job/"${c_cronjob_name}-manual"
}

function delete_jobs()
{
    job_prefix=$1
    postgres_cluster_jobs=$(kubectl get jobs -A | grep ${job_prefix} | awk '{print $1","$2}')

    if [[ ! -z $postgres_cluster_jobs ]]
    then

        for c in $postgres_cluster_jobs
        do 
           job_ns="$(echo $c | awk -F, '{print $1;}')"
           job_name="$(echo $c | awk -F, '{print $2;}')"
           echo -en "    "
	   kubectl delete job $job_name -n $job_ns
        done
    fi
}

function delete_backups()
{
    backup_prefix=$1
    for object in $(cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key' | grep $backup_prefix)
    do
        echo -en "    "
        echo -n "Deleting object $object"
        cray artifacts delete postgres-backup $object
    done
}

function patch_image()
{
    echo -en "    "
    kubectl patch cronjobs ${c_cronjob_name} -n ${c_ns} --type=json \
	    -p="[{'op': 'replace', 'path': '/spec/jobTemplate/spec/template/spec/containers/0/image', \
	    'value': \"$image_to_patch\" }]"
}


function main()
{
    failed=0
    check_image

    postgres_clusters_wBackup=$(kubectl get cronjobs -A | grep postgresql-db-backup | awk '{print $1","$2}')
    if [[ -z $postgres_clusters_wBackup ]]
    then
        echo "No Postgresql clusters have automatic backups set in cron jobs."
    else

        echo -e "\nList all initial postgres backups:"
        cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key'
	
        echo -e "\nCreating postgresql backups for ..."
        for c in $postgres_clusters_wBackup
        do

            c_ns="$(echo $c | awk -F, '{print $1;}')"
            c_cronjob_name="$(echo $c | awk -F, '{print $2;}')"
	    c_backup_prefix=${c_cronjob_name%"ql-db-backup"}              # remove suffix 'ql-db-backup'
            c_backup_prefix=${c_backup_prefix#"cray-"}                    # remove prefix 'cray-'
            c_backup_prefix=$(kubectl get postgresql -n ${c_ns} | grep $c_backup_prefix |awk '{print $1}')
    
	    # Check to see if this is only for a single cluster
	    if [[ ! -z $postgres_to_backup ]] && [[ "$postgres_to_backup" != "$c_cronjob_name" ]]
	    then
	        continue
	    fi

	    echo "* $c_cronjob_name: "

            echo "  - Suspend the backup"
            suspend_backup

            echo "  - Delete existing jobs"
            delete_jobs "$c_cronjob_name"

            echo "  - Delete existing backups"
            delete_backups "$c_backup_prefix"

            echo "  - Patch the cray-postgres-db-backup image"
            patch_image

            echo "  - Create manual job"
	    create_manual_job

	    echo "  - Wait for the backup job to complete"
            wait_for_job 

            postgres_backup_count=$(cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key' | grep -c "$c_backup_prefix")
            echo "  - Checking for backups"
            if [[ "$postgres_backup_count" -eq 2 ]]
            then 
	        echo "  - Delete manual job"
                delete_manual_job

                echo "  - Resume the backup"
                resume_backup

                echo "  -> Success"
            else
                echo "  - Resume the backup"
                resume_backup
    
                echo "  -> Failed"
                failed=1
            fi
        done

        echo -e "\nList all current postgres backups:"
        cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key'
 
        if [[ "$failed" -eq 1 ]]
        then 
            echo -e "\nNot all Postgres backups have been successfully re-generated."
        else
            echo -e "\nPostgres backup(s) have been successfully regenerated."
        fi
    fi
}

# --- main --- #
main

exit 0
