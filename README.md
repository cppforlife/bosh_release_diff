# BoshReleaseDiff

Shows detailed information about BOSH releases. It could be used for:

- Looking at job template properties

- Comparing job template properties across multiple release versions

- Cross referencing job template properties with a deployment manifest


## Usage

```
git clone https://github.com/cppforlife/bosh_release_diff
cd bosh_release_diff
bundle install
```

Basic:

```
bundle exec bosh diff release cf-147.tgz
```

Pass in multiple releases, though passing in 
multiple versions of the same release tends to be more useful:

```
bundle exec bosh diff release cf-147.tgz cf-148.tgz cf-149.tgz
```

Focus only on the changes:

```
bundle exec bosh diff release cf-147.tgz cf-148.tgz --changes job_added,property_added
```

Include one or more deployment manifests
for easier cross referencing of properties:

```
bundle exec bosh diff release cf-147.tgz cf-148.tgz cf.yml
```

Misc:

```
bundle exec bosh diff release cf-147.tgz --debug
bundle exec bosh diff release cf-147.tgz --jobs cloud_controller,uaa
bundle exec bosh diff release cf-147.tgz --packages
```


## Example output

```
...

- nats
  ∟ [cf-release/154.1-dev] present; 10 prop(s), 5 package(s)

  Properties: 
  - nats.address (NATS address)
    ∟ [cf-release/154.1-dev] present; no default
      ∟ [nats@cf.yml] set to "172.16.214.11"

  - nats.authorization_timeout (After accepting a connection, wait up to this many seconds for credentials.)
    ∟ [cf-release/154.1-dev] present; defaults to 15
      ∟ [nats@cf.yml] not set

  - nats.machines (IP of each NATS cluster member.)
    ∟ [cf-release/154.1-dev] present; no default
      ∟ [nats@cf.yml] not set

  - nats.password (Password for server authentication.)
    ∟ [cf-release/154.1-dev] present; no default
      ∟ [nats@cf.yml] set to "asdfasdfasdf"

  - nats.port (The port for the NATS server to listen on.)
    ∟ [cf-release/154.1-dev] present; no default
      ∟ [nats@cf.yml] set to 4222

  - nats.use_gnatsd (Using gnatsd or ruby nats server)
    ∟ [cf-release/154.1-dev] present; no default
      ∟ [nats@cf.yml] not set

  - nats.user (Username for server authentication.)
    ∟ [cf-release/154.1-dev] present; no default
      ∟ [nats@cf.yml] set to "nats"

  - networks.apps
    ∟ [cf-release/154.1-dev] present; no default
      ∟ [nats@cf.yml] set to "default"

  - syslog_aggregator.address (The address of the syslog_aggregator job.)
    ∟ [cf-release/154.1-dev] present; no default
      ∟ [nats@cf.yml] set to "172.16.214.13"

  - syslog_aggregator.port (The port used by the syslog_aggregator job.)
    ∟ [cf-release/154.1-dev] present; no default
      ∟ [nats@cf.yml] set to 54321

```
