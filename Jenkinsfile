@Library("dst-shared") _

rpmBuild(
    githubPushRepo = "Cray-HPE/hms-test",
    channel: "casmhms-builds",
    product: "ct-tests",
    target_node: "ncn",
    slack_notify: ["FAILURE", "FIXED"]
)
