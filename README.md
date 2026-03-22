# actions-logsage

GitHub Action that analyzes failed CI output with [LogSage](https://github.com/UreaLaden/log-sage) and surfaces the most likely root cause — with supporting evidence and actionable next steps.

## Usage

**Wrap a command** — LogSage runs automatically if it fails:

```yaml
- uses: UreaLaden/actions-logsage@v1
  with:
    run: npm test
```

**Analyze an existing log file** — use `if: failure()` to trigger after a failing step:

```yaml
- uses: UreaLaden/actions-logsage@v1
  if: failure()
  with:
    log-file: path/to/build.log
```

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `run` | No | — | Shell command to execute. Output is captured and analyzed on failure. Takes precedence over `log-file`. |
| `log-file` | No | — | Path to captured CI output to analyze. Ignored when `run` is provided. |
| `github-token` | No | `github.token` | GitHub token for posting PR comments. Requires `pull-requests: write`. |
| `post-comment` | No | `'true'` | Set to `'false'` to disable automatic PR comment posting. |
| `version` | No | `latest` | LogSage release version to install (e.g. `1.0.1`) |

## Outputs

| Output | Description |
|---|---|
| `result` | LogSage CI summary as a string |
| `result-file` | Path to the file containing the full LogSage output |

## Examples

### Wrap a command with automatic PR comment (recommended)

When a command fails, LogSage analyzes the output and posts the result as a PR comment. On re-runs the comment is updated in place — no duplicates. Set `post-comment: 'false'` to disable.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
      - uses: actions/checkout@v4

      - name: Test with LogSage analysis
        uses: UreaLaden/actions-logsage@v1
        with:
          run: npm test
```

### Wrap a command (no PR comment)

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Test and analyze failures
        id: logsage
        uses: UreaLaden/actions-logsage@v1
        with:
          run: npm test
          post-comment: 'false'

      - name: Print LogSage result
        if: failure()
        run: echo "${{ steps.logsage.outputs.result }}"
```

### Analyze an existing log file

```yaml
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - name: Analyze logs
        id: logsage
        if: failure()
        uses: UreaLaden/actions-logsage@v1
        with:
          log-file: ${{ runner.temp }}/build.log

      - name: Print result
        if: failure()
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
