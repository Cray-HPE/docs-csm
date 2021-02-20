@Library("dst-shared@release/shasta-1.4") _
rpmBuild (
    githubPushRepo : "Cray-HPE/docs-csm-install",
    githubPushBranches: "release/.*|main",
    masterBranch : "main",
    specfile : "docs-csm-install.spec",
    product : "csm",
    target_node : "ncn",
    fanout_params: ["sle15sp2"],
    channel : "metal-ci-alerts",
    slack_notify : ['', 'SUCCESS', 'FAILURE', 'FIXED']
)
