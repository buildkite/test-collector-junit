# Buildkite Collector for JUnit

A [Buildkite Test Analytics](https://buildkite.com/test-analytics) collector for JUnit files ✨

📦 **Supported CI systems:** Buildkite, GitHub Actions, CircleCI, and others via the `BUILDKITE_ANALYTICS_*` environment variables.

## 👉 Usage

Using curl:

```sh
cat junit.xml | \
  TEST_ANALYTICS_TOKEN=xyz \
  bash -c "`curl -sL https://raw.githubusercontent.com/buildkite/collector-junit/main/buildkite-collector-junit`"
```

Using Docker:

```sh
cat junit.xml | \
  docker run -e TEST_ANALYTICS_TOKEN=xyz buildkite-collector-junit
```

When using Docker, make sure to pass through the required environment variables for your CI system. For example, use the following command if you're running it within a Buildkite job:

```sh
cat junit.xml | \
  docker run \
    -e TEST_ANALYTICS_TOKEN \
    -e BUILDKITE_BUILD_NUMBER \
    -e BUILDKITE_JOB_ID \
    -e BUILDKITE_BRANCH \
    -e BUILDKITE_COMMIT \
    -e BUILDKITE_MESSAGE \
    -e BUILDKITE_BUILD_URL \
    buildkite-collector-junit
```

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

Bug reports and pull requests are welcome on GitHub at https://github.com/buildkite/collector-junit

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
