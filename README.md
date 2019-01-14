# crl_copy

Chef cookbook to install and configure the [CRL Copy PS script from Script Center](https://gallery.technet.microsoft.com/scriptcenter/Powershell-CRL-Copy-v3-d8d5ff94).

## Table of contents

1. [Requirements](#requirements)
    * [Platforms](#platforms)
    * [Cookbooks](#cookbooks)
2. [Usage](#usage)
3. [Attributes](#attributes)
4. [Recipes](#recipes)
5. [Versioning](#versioning)
6. [License and Author](#license-and-author)
7. [Contributing](#contributing)

## Requirements

### Platforms

This cookbook supports:

* Windows

### Cookbooks

This cookbook depends on the following cookbooks:

* pspki

## Usage

TODO: *Explain how to use the cookbook*

## Attributes

Attributes in this cookbook:

| Key                                                  | Type   | Description                                                                                          | Default                    |
| ---------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------- | -------------------------- |
| `['crl_copy']['eventvwr']['event_id']`               | Int    | Configures the event ID                                                                              | `5000`                     |
| `['crl_copy']['eventvwr']['event_source']`           | String | Configures the event source                                                                          | `CRL Copy Process`         |
| `['crl_copy']['smtp']['from']`                       | String | Configures mail notification sender address                                                          | `nil`                      |
| `['crl_copy']['smtp']['published_notify']`           | String | Configures whether to send published notification                                                    | `false`                    |
| `['crl_copy']['smtp']['send_mail']`                  | String | Configures whether to send mail notifications                                                        | `false`                    |
| `['crl_copy']['smtp']['server']`                     | String | Configures mail server to use                                                                        | `nil`                      |
| `['crl_copy']['smtp']['threshold']`                  | Int    | Configures threshold for mail notifications                                                          | `2`                        |
| `['crl_copy']['smtp']['title']`                      | String | Configures mail notification subject                                                                 | `CRL Copy Process Results` |
| `['crl_copy']['smtp']['to']`                         | String | Configures mail notification recipient addresses                                                     | `nil`                      |
| `['crl_copy']['warnings']['threshold']`              | Int    | Configures threshold value                                                                           | `5`                        |
| `['crl_copy']['warnings']['threshold_unit']`         | String | Configures unit for threshold (one of "Days", "Hours", "Minutes" or "Seconds")                       | `Hours`                    |
| `['crl_copy']['windows_task']['frequency']`          | String | Configures scheduled task frequency unit (one of "Monthly", "Weekly", "Daily", "Hourly" or "Minute") | `Minute`                   |
| `['crl_copy']['windows_task']['frequency_modifier']` | Int    | Configures scheduled task frequency modifier                                                         | `30`                       |
| `['crl_copy']['windows_task']['password']`           | String | Configures a password for the scheduled task user                                                    | `nil`                      |
| `['crl_copy']['windows_task']['user']`               | String | Configures the user to run the task as                                                               | `SYSTEM`                   |

## Recipes

### `crl_copy::default`

Simple recipe that creates `crl_copy` resources by iterating over the `node['crl_copy']['master_crls']` attribute.

## Resources

### `crl_copy`

#### Actions

- `:create` - Creates a scheduled task that runs the CRL Copy script to copy a CRL to a CDP

#### Properties

`master_crl`: String, required: true, name_property: true
`cdps`: [Array, Hash], required: true, default: `nil`
`cluster_name`: String, required: false, default: `nil`
`outfile`: [Array, String], required: false, default: `nil`

`eventvwr_event_id`: [Integer, String], required: false, default: `lazy { node['crl_copy']['eventvwr']['event_id'] }`
`eventvwr_event_source`: String, required: false, default: `lazy { node['crl_copy']['eventvwr']['event_source'] }`

`smtp_from`: String, required: false, default: `lazy { node['crl_copy']['smtp']['from'] }`
`smtp_published_notify`: [TrueClass, FalseClass], required: false, default: `lazy { node['crl_copy']['smtp']['published_notify'] }`
`smtp_send_mail`: [TrueClass, FalseClass], required: false, default: `lazy { node['crl_copy']['smtp']['send_mail'] }`
`smtp_server`: String, required: false, default: `lazy { node['crl_copy']['smtp']['server'] }`
`smtp_threshold`: [Integer, String], required: false, default: `lazy { node['crl_copy']['smtp']['threshold'] }`
`smtp_title`: String, required: false, default: `lazy { node['crl_copy']['smtp']['title'] }`
`smtp_to`: [Array, String], required: false, default: `lazy { node['crl_copy']['smtp']['to'] }`

`warnings_threshold`: [Integer, String], required: false, default: `lazy { node['crl_copy']['warnings']['threshold'] }`
`warnings_threshold_unit`: String, required: false, default: `lazy { node['crl_copy']['warnings']['threshold_unit'] }, `regex:` /^(Days|Hours|Minutes|Seconds)$/i`

`windows_task_frequency`: String, required: false, default: `lazy { node['crl_copy']['windows_task']['frequency'] }, `regex:` /^(Monthly|Weekly|Daily|Hourly|Minute)$/i`
`windows_task_frequency_modifier`: [Integer, String], required: false, default: `lazy { node['crl_copy']['windows_task']['frequency_modifier'] }`
`windows_task_password`: String, required: false, default: `lazy { node['crl_copy']['windows_task']['password'] }`
`windows_task_user`: String, required: false, default: `lazy { node['crl_copy']['windows_task']['user'] }`

## Versioning

This cookbook uses [Semantic Versioning 2.0.0](http://semver.org/).

Given a version number MAJOR.MINOR.PATCH, increment the:

* MAJOR version when you make functional cookbook changes,
* MINOR version when you add functionality in a backwards-compatible manner,
* PATCH version when you make backwards-compatible bug fixes.

## License and Authors

Authors and contributors:

* Stephen Hoekstra <shoekstra@schubergphilis.com>

```
Copyright 2016-2019 Stephen Hoekstra <stephenhoekstra@gmail.com>
Copyright 2016-2019 Schuberg Philis

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## Contributing

We welcome contributed improvements and bug fixes via the usual work flow:

1. Fork this repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new pull request
