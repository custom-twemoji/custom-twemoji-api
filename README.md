<p align="center">
  <img
    src="assets/header.jpg"
    alt="Custom Twemoji API logo"
    title="Custom Twemoji API logo"
  />
  An API that let's you combine <a href="https://twemoji.twitter.com">Twitter's emojis<a/>.
</p>

🚧 WIP - Beta 🚧

## :slightly_smiling_face: Face Twemojis

- `GET /faces`
  - Returns JSON list of all faces and their layers by feature
- `GET /faces/random`
  - Default is 100% chance of having a head but 50% for all other features
  - Customize feature probability by passing in a Boolean (true or false) or decimal number between 0 and 1 (e.g. `/faces/random?eyes=0.75&nose=false` has a 75% chance of having eyes and 0% for nose)
- `GET /faces/{emoji}`

Valid emoji formats:

- 🙂
- 1f383
- U+1f383

### URL Parameters

After the endpoint, you can add a question mark (`?`) and pass in URL parameters as key-value pairs (`key=value`) separated by ampersands (`&`).

```txt
GET /faces/{emoji}?key1=value1&key2=value2
```

- <details>
  <summary><b>Facial Features</b></summary>
  <br>

    - Key: facial feature
    - Value: emoji

  <br>

  Each feature is a layer and the order in which they're stacked impacts what will be seen or hidden in the emoji. This is the list of features in default stacking order from bottom to top.

  1. head
  1. cheeks
  1. mouth
  1. nose
  1. eyes
  1. eyewear
  1. headwear
  1. other

  <br>

  If you want to specify your own stacking order, pass in the key-value pair `order=manual` anywhere in the request. The stacking will follow the order you pass in parameters, with the first parameter being at the bottom.

  **Example:** If you want...

  - the eyes of [263a](https://unicode-table.com/en/263A) ☺️
  - the mouth of [2639](https://unicode-table.com/en/2639/) ☹️
  - the eyewear of [1f978](https://unicode-table.com/en/1F978/) 🥸
  - everything else of [1f47f](https://unicode-table.com/en/1F47F/) 👿

  <br>

  Your request will look like this:

  ```txt
  /faces/1f47f?eyes=263a&mouth=2639&eyewear=1f978

  # Spaced out for easy reading
  /faces /1f47f ? eyes=263a & mouth=2639 & eyewear=1f978
  ```

  If you want the eyes to be above the eyewear, add in `order=manual` and move eyes in front of eyewear:

  ```txt
  /faces/1f47f?mouth=2639&eyewear=1f978&eyes=263a&order=manual

  # Spaced out for easy reading
  /faces /1f47f ? mouth=2639 & eyewear=1f978 & eyes=263a & order=manual
  ```

</details>

- <details>
  <summary><b>File Formats & Output</b></summary>
  <br>

  Defaults:

  - File format: `svg`
  - Output: MIME type of `image/svg+xml`
  - Height and width set to `100%`

  ### Size (`size=100`)

  Specify the number of pixels (`px`) for the emoji's height and width.

  ### PNG (`file_format=png`)

  Defaults:

  - Output: MIME type of `image/png`
  - Height and width set to `36px`

  With `output=json` returns as [Base64](https://developer.mozilla.org/en-US/docs/Glossary/Base64)

  ### Output

  #### JSON (`output=json`)

  File format is returned as `resource` and also includes licensing information.

  #### Download (`output=download`)

  The default name of the file returned is a modified version of your request parameters. The equals signs (`=`) and ampersands (`&`) are replaced with a minus sign (`-`) and these characters `_-_`

  ##### Filename (`filename={your_name}`)

  If you want to name your download file, pass in `filename=` with a value of your choosing.

  Example Request:

  ```txt
  /faces/263a?file_format=png&download=true&filename=amazing_emoji
  ```

  File returned: `amazing_emoji.png`

</details>

## Contributing

This project is open for anyone to contribute or raise issues.

Follow these steps to contribute:

1. Fork this repository
1. Follow the [Run Locally](#run-locally) steps
1. Make and test changes
1. Run [Rubocop](https://rubocop.org) to check files for linting/formatting: `rubocop`
1. When satisfied with your changes, open a pull request with screenshots of your testing evidence

## Run Locally

1. Clone the repository
1. Install [Ruby](https://www.ruby-lang.org/en/) if you haven't already: [www.ruby-lang.org](https://www.ruby-lang.org/en/documentation/installation/)
1. Install [Bundler](https://bundler.io/) if you haven't already: `gem install bundler`
1. Install Ruby dependencies with bundler: `bundle`
1. Follow the [Getting Started](#getting-started) steps
1. Run application locally using Rack: `rackup`
1. Go to this URL in a browser to ensure it redirects to the [Custom Twemoji API GitHub repository](https://github.com/blakegearin/custom-twemoji-api): `http://localhost:9292`
1. Stop application: `CTRL + C`

## License

- Code licensed under the [MIT License](LICENSE)
- Graphics licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- Twemoji licensing can be found on [Twitter](https://twemoji.twitter.com)

Not affiliated with Twitter Inc. or any of their affiliations
