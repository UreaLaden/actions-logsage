# actions-logsage

GitHub Action that runs [LogSage](https://github.com/UreaLaden/log-sage) against a CI log file and surfaces the most likely root cause of failures.

## Usage

```yaml
- uses: UreaLaden/actions-logsage@v1
  with:
    log-file: path/to/build.log   # optional — omit to pipe stdin
    version: latest               # optional — defaults to latest release
```

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `log-file` | No | — | Path to the CI log file to analyze |
| `version` | No | `latest` | LogSage release version to install (e.g. `1.0.1`) |

## Outputs

| Output | Description |
|---|---|
| `result` | LogSage CI summary as a string |
| `result-file` | Path to the file containing the full LogSage output |

## Example — analyze a failed build log

```yaml
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - name: Analyze logs
        id: logsage
        uses: UreaLaden/actions-logsage@v1
        with:
          log-file: ${{ runner.temp }}/build.log

      - name: Print result
        run: echo "${{ steps.logsage.outputs.result }}"
```

## Supported platforms

| OS | x64 | ARM64 |
|---|---|---|
| Linux | ✓ | ✓ |
| macOS | ✓ | ✓ |
| Windows | ✓ | — |

## License

MIT
