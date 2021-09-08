@Library("dst-shared@master") _
rpmBuild (
    githubPushRepo : "Cray-HPE/docs-csm",
    githubPushBranches: "release/.*|main",
    masterBranch : "main",
    specfile : "docs-csm.spec",
    product : "csm",
    target_node : "ncn",
    fanout_params: ["sle15sp2", "sle15sp3"],
    channel : "metal-ci-alerts",
    slack_notify : ['', 'SUCCESS', 'FAILURE', 'FIXED']
)
