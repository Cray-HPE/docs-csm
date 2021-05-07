RESULTS=vcs-content
mkdir $RESULTS
for repo in $(curl -s https://api-gw-service-nmn.local/vcs/api/v1/orgs/cray/repos | jq -r '.[] | .name')
do
    git clone --mirror https://api-gw-service-nmn.local/vcs/cray/${repo}.git
    cd ${repo}.git
    git bundle create ${repo}.bundle --all
    cp ${repo}.bundle ../$RESULTS
    cd ..
    rm -r $repo.git
done
