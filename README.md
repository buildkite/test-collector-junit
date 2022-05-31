# Buildkite Collector for curl

A [Buildkite Test Analytics](https://buildkite.com/test-analytics) collector that uses `curl` to upload JSON and JUnit files ✨

📦 **Supported CI systems:** Buildkite, GitHub Actions, CircleCI, and others via the `BUILDKITE_ANALYTICS_*` environment variables.

## 👉 Usage

Using curl from within your build scripts:

```sh
# For a JUnit file
cat junit.xml | \
  BUILDKITE_ANALYTICS_TOKEN=xyz \
  bash -c "`curl -sL https://raw.githubusercontent.com/buildkite/test-collector-curl/main/test-collector`" \
    --format junit
    
# For a Test Analytics JSON file
cat test-results.json | \
  BUILDKITE_ANALYTICS_TOKEN=xyz \
  bash -c "`curl -sL https://raw.githubusercontent.com/buildkite/test-collector-curl/main/test-collector`" \
    --format json
```

See the [Importing JSON](https://buildkite.com/docs/test-analytics/importing-json) and [Importing JUnit XML](https://buildkite.com/docs/test-analytics/importing-junit-xml) documentation for more details.

<!-- Using Docker:

```sh
# For a JUnit file
cat junit.xml | \
  docker run -e BUILDKITE_ANALYTICS_TOKEN=xyz buildkite-test-collector \
    --format junit

# For a Test Analytics JSON file
cat test-results.json | \
  docker run -e BUILDKITE_ANALYTICS_TOKEN=xyz buildkite-test-collector \
    --format json
```

When using Docker, make sure to pass through the required environment variables for your CI system. For example, use the following command if you're running it within a Buildkite job:

```sh
cat junit.xml | \
  docker run \
    -e BUILDKITE_ANALYTICS_TOKEN \
    -e BUILDKITE_BUILD_NUMBER \
    -e BUILDKITE_JOB_ID \
    -e BUILDKITE_BRANCH \
    -e BUILDKITE_COMMIT \
    -e BUILDKITE_MESSAGE \
    -e BUILDKITE_BUILD_URL \
    buildkite-test-collector \
      --format junit
```

-->

## ⚒ Developing

After cloning the repository, install the [BATS](https://bats-core.readthedocs.io/) testing dependencies:

```
git submodule init
```

And run the tests:

```
./test/bats/bin/bats test/
```

Useful resources for developing collectors include the [Buildkite Test Analytics docs](https://buildkite.com/docs/test-analytics) and the [RSpec and Minitest collectors](https://github.com/buildkite/rspec-buildkite-analytics).

## 👩‍💻 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/buildkite/test-collector-curl

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
