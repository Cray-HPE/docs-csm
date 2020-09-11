@Library("dst-shared@master") _
rpmBuild (
    specfile : "cray-metal-docs-ncn.spec",
    product : "shasta-premium",
    target_node : "ncn",
    fanout_params: ["sle15sp2"],
    channel : "metal-ci-alerts",
    slack_notify : ['', 'SUCCESS', 'FAILURE', 'FIXED']
)
