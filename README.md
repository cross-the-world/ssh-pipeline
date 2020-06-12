# SSH Pipeline

[Github actions](https://help.github.com/en/actions/creating-actions/creating-a-docker-container-action)

This action allows doing in order
* ssh if defined

## Inputs
see the [action.yml](./action.yml) file for more detail imformation.

### `host`

**Required** ssh remote host.

### `port`

**NOT Required** ssh remote port. Default 22

### `user`

**Required** ssh remote user.

### `pass`

**NOT Required** ssh remote pass.

### `key`

**NOT Required** ssh remote key as string.

### `connect_timeout`

**NOT Required** connection timeout to remote host. Default 30s

### `script`

**NOT Required** execute commands on ssh.


## Usages
see the [deploy.yml](./.github/workflows/deploy.yml) file for more detail imformation.

```yaml
- name: ssh pipelines
  uses: cross-the-world/ssh-pipeline@master
  env:
    WELCOME: "ssh pipeline"
  with:
    host: ${{ secrets.DC_HOST }}
    user: ${{ secrets.DC_USER }}
    pass: ${{ secrets.DC_PASS }}
    port: ${{ secrets.DC_PORT }}
    connect_timeout: 10s
    script: |
      (rm -rf /home/github/test || true)
      ls -la  
      echo $WELCOME 
      mkdir -p /home/github/test/test1 && 
      mkdir -p /home/github/test/test2 &&
```

  
