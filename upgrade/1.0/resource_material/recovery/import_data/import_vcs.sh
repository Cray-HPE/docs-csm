SOURCE=vcs-content
VCS_USER=crayvcs
VCS_PASSWORD=

git config --global credential.helper store
echo "https://${VCS_USER}:${VCS_PASSWORD}@api-gw-service-nmn.local" > ~/.git-credentials

for file in $(ls $SOURCE)
do
    repo=$(echo $file | sed 's/.bundle$//')
    git clone --mirror ${SOURCE}/${repo}.bundle
    cd ${repo}.git
    git remote set-url origin https://api-gw-service-nmn.local/vcs/cray/${repo}.git
    git push
    cd ..
    rm -r ${repo}.git
done
