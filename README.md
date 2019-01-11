# crl_copy

Chef cookbook to install and configure the [CRL Copy PS script from Script Center](https://gallery.technet.microsoft.com/scriptcenter/Powershell-CRL-Copy-v3-d8d5ff94).

## Table of contents

1. [Requirements](#requirements)
    * [Platforms](#platforms)
    * [Cookbooks](#cookbooks)
2. [Usage](#usage)
3. [Attributes](#attributes)
4. [Recipes](#recipes)
    * [Public Recipes](#public-recipes)
5. [Versioning](#versioning)
6. [Testing](#testing)
7. [License and Author](#license-and-author)
8. [Contributing](#contributing)

## Requirements

### Platforms

This cookbook supports:

* Windows

### Cookbooks

This cookbook does not depend on any other cookbooks.

## Usage

TODO: *Explain how to use the cookbook*

## Attributes

Attributes in this cookbook:

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['crl_copy']['eventvwr']['event_high']</tt></td>
    <td>Int</td>
    <td>Some info about the attribute</td>
    <td><tt>1</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['eventvwr']['event_id']</tt></td>
    <td>Int</td>
    <td>Some info about the attribute</td>
    <td><tt>5000</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['eventvwr']['event_information']</tt></td>
    <td>Int</td>
    <td>Some info about the attribute</td>
    <td><tt>4</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['eventvwr']['event_source']</tt></td>
    <td>String</td>
    <td>Some info about the attribute</td>
    <td><tt>CRL Copy Process</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['eventvwr']['event_warning']</tt></td>
    <td>Int</td>
    <td>Some info about the attribute</td>
    <td><tt>2</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['smtp']['from']</tt></td>
    <td>String</td>
    <td>Some info about the attribute</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['smtp']['published_notify']</tt></td>
    <td>String</td>
    <td>Some info about the attribute</td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['smtp']['send_mail']</tt></td>
    <td>String</td>
    <td>Some info about the attribute</td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['smtp']['server']</tt></td>
    <td>String</td>
    <td>Some info about the attribute</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['smtp']['threshold']</tt></td>
    <td>Int</td>
    <td>Some info about the attribute</td>
    <td><tt>2</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['smtp']['title']</tt></td>
    <td>String</td>
    <td>Some info about the attribute</td>
    <td><tt>CRL Copy Process Results</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['smtp']['to']</tt></td>
    <td>String</td>
    <td>Some info about the attribute</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['crl_copy']['warnings']['threshold']</tt></td>
    <td>Int</td>
    <td>Some info about the attribute</td>
    <td><tt>5</tt></td>
  </tr>
</table>

## Recipes

### Public Recipes

#### `crl_copy::default`

Installs and configures script and scheduled task to manage CRL distribution.

## Versioning

This cookbook uses [Semantic Versioning 2.0.0](http://semver.org/).

Given a version number MAJOR.MINOR.PATCH, increment the:

* MAJOR version when you make functional cookbook changes,
* MINOR version when you add functionality in a backwards-compatible manner,
* PATCH version when you make backwards-compatible bug fixes.

## Testing

    rake integration:cloud        # Run Test Kitchen with cloud plugins
    rake integration:vagrant      # Run Test Kitchen with Vagrant
    rake spec                     # Run ChefSpec examples
    rake style                    # Run all style checks
    rake style:chef               # Run Chef style checks
    rake style:ruby               # Run Ruby style checks
    rake style:ruby:auto_correct  # Auto-correct RuboCop offenses
    rake travis                   # Run all tests on Travis

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
