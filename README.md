
# terrastorm

A small wrapper script for multi-environment, multi-configuration terraform deployments

## About

The purpose of this wrapper is to facilitate dynamic[\*] configuration shared between multiple environments and the creation of dynamic[\*] resources within those environments.

_[*] Note: This is explicity what hashicorp/terraform recommend against. Be sure you know what you are doing before diving down this rabbit hole. It's a trap. Etc._

## Requirements

A specific folder hierarchy:
```
working directory
|
|- config/
|  |
|  |- shared/
|  |  |
|  |  |- all/ <.tfvars>
|  |  |- datacentre/ <.tfvars>
|  |  |- environment/ <.tfvars>
|  |
|  |- <your-datacentre-name>/ <.tfvars>
|     |
|     |- <your-first-environment-name>/ <.tfvars>
|     |- <your-second-environment-name>/ <.tfvars>
|
|- datacentre/ <.tf>        <-- a module defining a 'top-level' datacentre/root
|
|- environment/ <.tf>       <-- a module defining sub-level environment(s) under a datacentre
```

Note: The last two non-shared modules above ^ defining "datacentre" and "environment" are optional. You can substitute their names and locations, following the usage examples provided below. The shared `config/shared/datacentre` and `config/shared/environment` paths are written into the script and you would need to modify the script if you want to change their cosmetic names.

## Datacentres vs environments

The principle of a top-level "datacentre" with sub-level "environments" follows the best practice guidelines of &lt;insert cloud provider(s) here&gt; to have a top-level account used for billing only, with sub-level accounts used for actual services.

## Usage

`plan`|`apply`|`destroy`:
```shell
./terrastorm.sh  <organisation>  <environment>  <action>  [extra-args]        <configuration>

# EG: plan a top level "root" datacentre
./terrastorm.sh  myorg           eu-root-acc    plan      [-target <module>]  datacentre
```

`import`:
```shell
./terrastorm.sh  <organisation>  <environment>  <action>  <configuration>       <module> <resource>

# EG: import a resource from a sub-level "production" environment
./terrastorm.sh  myorg           prod-subacc    import    --config environment  <module[ref]> <resource-identifier>
```

`state`:
```shell
./terrastorm.sh  <organisation>  <environment>  <action>  <resource-identifier>

# EG: remove an item from state
./terrastorm.sh  yourorg         your-env       state rm  <resource>
```

## How it works

TLDR: the script fetches all `.tfvars` files from the subdirectories depending on what type of configuration (datacentre/environment) you have specified.

The idea is that you have common identicial configuration that you require in multiple environments, so you define this configuration under `config/shared` and define the environment-specific configuration under `config/<your-datacentre-name|your-environment-name>` and the script loads these variable inputs so they can be passed into your main "environment" module definition. At this point, within your environment module, you would merge the variable contents together (By resource type), before passing a single variable set (Per resource type) to downstream modules/providers for the resources to be created.

Specifically:
- `shared/all/*.tfvars` will be loaded for any type of configuration
- `shared/<datacentre|environment>/*.tfvars` will be loaded for only that type of configuration
- `.state` files will be gathered from the corresponding directories
- the above will be will be constructed into the final terraform command which is then invoked

Note: Typically in non-hobby environments you would use a shared remote state provider in which case you can comment out the state handling directives as you would have your own within the provider configuration. The local state handling is implemented for the use-case _'probably-works-for-most-people downloading and running the script'_ so that you can experiment with it.

## Troubleshooting

If you are referencing entire configurations or `-target` on an entire module, you will generally have a smooth experience.

### targeting resources

If you are -`target` on name-based resources created using the `for_each()` iterator in the modules, terraform will require you to quote `"` the inputs. Currently, this will get removed in the script parsing so you will need to escape `\` the double quotes for the name.
EG:
```
-target module.s3.module.bucket[\"some-bucket-name\"]
```

If you are using `-target` on specific resources created using `count()` in the modules, you will not need to quote and you should be ok.

## Contributing

Spotted an error? Something functional to add value? Send me a pull request!

1. Fork it (<https://github.com/yourname/yourproject/fork>)
2. Create your feature branch (`git checkout -b feature/foo`)
3. Commit your changes (`git commit -am 'Add some foo'`)
4. Push to the branch (`git push origin feature/foo`)
5. Create a new Pull Request

## License

MIT license. See [LICENSE](LICENSE) for full details.
