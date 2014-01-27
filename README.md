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

Filter down by values:

```
bundle exec bosh diff release cf-147.tgz cf-148.tgz --values job_name=uaa,property_name=~nats
```

Include one or more deployment manifests
for easier cross referencing of properties:

```
bundle exec bosh diff release cf-147.tgz cf-148.tgz cf.yml
```

Misc:

```
bundle exec bosh diff release cf-147.tgz --debug
bundle exec bosh diff release cf-147.tgz --packages
```


## Example output

Cross-referencing deployment manifest property values with release properties:

```
$ bundle exec bosh diff release ~/Downloads/cf-154.1-dev.tgz ~/cf.yml
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

Finding which properties were added in a new release version without defaults:

```
$ bundle exec bosh diff release ~/Downloads/cf-147.tgz ~/Downloads/cf-154.tgz \
  --changes property_added                                                    \
  --values job_name=gorouter,property_has_default_value=false

WARNING: loading local plugin: lib/bosh/cli/commands/diff_release.rb

Extracted releases in 11 sec(s)

Using releases: cf/147 (07e0aa91*), cf/154 (52777d46*)

Jobs (aka job templates):
- gorouter
  ∟ [cf/147] present; 13 prop(s), 3 package(s)
  ∟ [cf/154] present; 15 prop(s), 4 package(s)

  Properties:
  - loggregator_endpoint.host (The host used to emit messages to the Loggregator)
    ∟ [cf/147] not present
    ∟ [cf/154] added; no default

  - loggregator_endpoint.shared_secret (The key used to sign log messages)
    ∟ [cf/147] not present
    ∟ [cf/154] added; no default

  - nats.machines (IP of each NATS cluster member.)
    ∟ [cf/147] not present
    ∟ [cf/154] added; no default

Compared in 0 sec(s)
```
