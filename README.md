# CyberArk Conjur - Jenkins World 2017 Demo
This demonstration will be presented during Jenkins World 2017 in San Francisco, CA on August 29th-31st at CyberArk Booth # 504.

## What does this demonstrate for CyberArk Conjur?
* Machine Identity
  * By granting a machine identity to the Jenkins Master, we can trust any communication authenticated with it's API Key going forward.  This allows [Summon](https://cyberark.github.io/summon) to use the Jenkins Master identity when reaching out to CyberArk Conjur for the secrets within [secrets.yml](secrets.yml).
* Role-Based Access Control (RBAC)
  * Jenkins Master received it's identity, was added as a Host in Conjur and granted an API Key, and was added to the jenkins/masters Layer (or group of Hosts) to receive the associated Policy ([policy.yml](policy.yml)).
* On-Demand Secrets Allowing Rotation
  * By using [Summon](https://cyberark.github.io/summon) rather than hardcoding the credentials, this allows us to retrieve the secrets on-demand allowing CyberArk Conjur to manage and rotate the AWS access keys while still serving out the secrets programatically, as needed.

## How it works?
Our JenkinsWorld2017 job in CloudBees Jenkins is tied to this repository.  When the job's build is run, the [sqsPost.py](sqsPost.py) script will be run in a Shell Command build step within Jenkins.  Rather than just calling `python sqsPost.py` to test it in the workspace, we are executing `summon python sqsPost.py` instead.

By having `summon` run the `python` provider, we can inject environment variables into `python` that the [sqsPost.py](sqsPost.py) script can reference when it runs.  `summon` will read [secrets.yml](secrets.yml) file and fetch the secret ID referenced within and place it in the given environment variable name in temporary memory.  For example: `ENV_VAR_NAME: !var /id/of/secret`

Our [sqsPost.py](sqsPost.py) script is grabbing the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, logging into AWS API and sending a message to a Simple Queue Service (SQS) queue called JenkinsWorld2017 with a 2 minute TTL.  The contents of the message are the values of the AWS secrets fetched from within CyberArk Conjur.

The secrets received in the message in AWS SQS can be checked against the Console Output of the Jenkins job build for confirmation of accuracy.

## Pre-Requisites
* CyberArk Conjur v4.x
  * [Community Edition](https://try.conjur.org) or [Enterprise Edition](https://try.conjur.org/try-conjur-enterprise.html)
* CyberArk Conjur CLI
  * [Installation Guide](https://developer.conjur.net/cli)
* Jenkins v2
  * [Jenkins OSS](https://jenkins.io/) or [CloudBees Jenkins](https://www.cloudbees.com/)
  * `sudo apt-get install jq` is needed for parsing JSON response.
  * `sudo apt-get install python27` is needed for testing [sqsPost.py](sqsPost.py).
* Amazon Web Services (AWS) [Free Tier Account](https://www.amazon.com/ap/signin?openid.assoc_handle=aws&openid.return_to=https%3A%2F%2Fsignin.aws.amazon.com%2Foauth%3Fresponse_type%3Dcode%26client_id%3Darn%253Aaws%253Aiam%253A%253A015428540659%253Auser%252Fawssignupportal%26redirect_uri%3Dhttps%253A%252F%252Fportal.aws.amazon.com%252Fbilling%252Fsignup%253Fnc2%253Dh_ct%2526redirect_url%253Dhttps%25253A%25252F%25252Faws.amazon.com%25252Fregistration-confirmation%2526state%253DhashArgs%252523%2526isauthcode%253Dtrue%26noAuthCookie%3Dtrue&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&action=&disableCorpSignUp=&clientContext=&marketPlaceId=&poolName=&authCookies=&pageId=aws.ssop&siteState=registered%2Cen_US&accountStatusPolicy=P1&sso=&openid.pape.preferred_auth_policies=MultifactorPhysical&openid.pape.max_auth_age=120&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&server=%2Fap%2Fsignin%3Fie%3DUTF8&accountPoolAlias=&forceMobileApp=0&language=en_US&forceMobileLayout=0)
  * Sending messages to Simple Queue Service (SQS) is considered free tier up to 1 million messages.
  * Use caution if planning to exceed 1 million messages within a one-month billing period.

## Setup
### Grant Machine Identity to Jenkins Master
1. Load [policy.yml](policy.yml) into CyberArk Conjur via CLI.
```
$ conjur authn login
$ conjur policy load --as-group security_admin policy.yml
```
2. Install CyberArk Conjur CLI on Jenkins Master.  Copy latest .deb release from [cyberark/conjur-cli](https://github.com/cyberark/conjur-cli/releases).
```
$ sudo curl -L -O https://github.com/cyberark/conjur-cli/releases/download/v5.4.0/conjur_5.4.0-1_amd64.deb
$ sudo dpkg -i ./conjur_5.4.0-1_amd64.deb
$ sudo apt-get install -f
```
3. Do the following on the Jenkins Master:
```
$ mkdir ~/src
$ cd ~
```
4. Copy [identify.sh](identify.sh) to the user running Jenkins' home directory on the Jenkins Master and change the commented variables for your environment.
5. Login to the CyberArk Conjur UI, click on "Layers" in the left sidebar navigation and select the Layer created by our [policy.yml](policy.yml).
6. Scroll down to the "Host Factory" section and click "Add" to add one.
7. Do the following on the Jenkins Master:
```
$ vi ~/src/hftoken.txt
Paste host factory token and save.
```
8. Retrieve Machine Identity for Jenkins Master:
```
$ chmod +x identify.sh
$ ./identify.sh
```
### Configure Job on Jenkins Master
1. Login to Jenkins Web Interface
2. Select `New Item` from left sidebar navigation.
3. Create a new Freestyle Project named `JenkinsWorldDemo`.
4. Under `Source Code Management`, select `Git` and use this repository forked under your GitHub user account.
5. Under `Build`, `Add build step` and choose `Execute shell` with the following command: `summon python sqsPost.py`
6. Save the job.

### Install Summon on Jenkins Master
1. Navigate to [Summon Releases](https://github.com/cyberark/summon/releases) and copy the URL to download the latest `summon-linux-amd64.tar.gz`.
2. Do the following from the Jenkins Master:
```
$ curl -L -O https://github.com/cyberark/summon/releases/download/v0.6.5/summon-linux-amd64.tar.gz
$ tar -xvzf summon-linux-amd64.tar.gz
$ mv summon /usr/local/lib
```

### Setup Simple Queue Service (SQS) in Amazon Web Services (AWS)
1. Login to Amazon Web Services (AWS) as your Free Tier account.
2. You should land on the `AWS services` page.  Select `Simple Queue Service` under `Messaging`.
3. Click the blue `Create New Queue` button.
4. Create a queue named `JenkinsWorldDemo`, select `FIFO Queue`, and click `Configure Queue`.
5. Change the `Message Retention Period` to `2 minutes` and click the blue `Create Queue` button.
6. You should now see `JenkinsWorldDemo.fifo` as an available queue.
7. Update the `queue_url=` value in [postSQS.py](postSQS.py) to reflect your proper region and AWS Account Number.

## Usage
1. Login to Jenkins Web Interface.
2. Select `JenkinsWorldDemo` from the dashboard.
3. Click `Build Now` in the left sidebar navigation.
4. After the Build Passes (or Fails), click the Job Number in the `Build History` pane.
5. Click `Console Output` in the left sidebar navigation.
```
Started by user CyberArk Demo
Building in workspace /root/operations-center/workspace/JenkinsWorldDemo
 > git rev-parse --is-inside-work-tree # timeout=10
Fetching changes from the remote Git repository
 > git config remote.origin.url https://github.com/infamousjoeg/jenkinsworld-e2e # timeout=10
Fetching upstream changes from https://github.com/infamousjoeg/jenkinsworld-e2e
 > git --version # timeout=10
using GIT_ASKPASS to set credentials GitHub Creds
 > git fetch --tags --progress https://github.com/infamousjoeg/jenkinsworld-e2e +refs/heads/*:refs/remotes/origin/*
 > git rev-parse refs/remotes/origin/master^{commit} # timeout=10
 > git rev-parse refs/remotes/origin/origin/master^{commit} # timeout=10
Checking out Revision 6f3f0dea7738d3e6fd6b11eded7f876159affb1e (refs/remotes/origin/master)
Commit message: "Delete host.json"
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 6f3f0dea7738d3e6fd6b11eded7f876159affb1e
 > git rev-list 6f3f0dea7738d3e6fd6b11eded7f876159affb1e # timeout=10
[JenkinsWorldDemo] $ /bin/sh -xe /tmp/jenkins6768624294872102283.sh
+ summon python sqsPost.py
Warning: this build has no associated authentication, so build permissions may be lacking, and downstream projects which cannot even be seen by an anonymous user will be silently skipped
Finished: SUCCESS
```
6. Login to Amazon Web Services (AWS) Management Console.
7. Navigate to the Simple Queue Service (SQS) where we configured the `JenkinsWorldDemo.fifo` queue earlier.
8. Select the `JenkinsWorldDemo.fifo` queue and select `Queue Actions` > `View/Delete Messages`.
9. Click the blue `Start Polling for Messages` and all messages received in the past 2 minutes will begin to appear.  The contents are a JSON blob of the Access Key ID and Secret Access Key retrieved from CyberArk Conjur.

## Summon
For more information on Summon, please visit [Summon on GitHub](https://cyberark.github.io/summon/).