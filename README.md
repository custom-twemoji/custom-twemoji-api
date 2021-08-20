<p align="center">
  <img
    src="assets/header.png"
    alt="Custom Twemoji API logo"
    title="Custom Twemoji API logo"
  />
  An API that let's you combine <a href="https://twemoji.twitter.com">Twitter's emojis<a/>.
</p>

## Face Emojis (`GET /faces`)

### Endpoints

The available endpoints correspond to the supported file formats.

- [SVG](https://www.w3schools.com/graphics/svg_intro.asp): `/svg`
- [PNG](https://www.lifewire.com/png-file-2622803): `/png`

You can optionally specify a "base" emoji by passing an ID before the file format. This saves from having to type out more URL parameters than is necessary.

```txt
GET /faces/263a/svg
```

### URL Parameters

After the endpoint, pass in URL parameters as key-value pairs (`?key=value`) separated by ampersands (`&`).

- <details>
  <summary><b>Facial Features</b></summary>
  <br>

    - Key: facial feature
    - Value: emoji ID

  <br>

  Each feature is a layer and the order in which they're stacked impacts what will be seen or hidden in the output emoji. This is the list of features in default stacking order from bottom to top.

  1. head
  1. headwear
  1. cheeks
  1. mouth
  1. nose
  1. eyes
  1. eyewear
  1. other

  <br>

  If you want to specify your own stacking order, pass in the key-value pair `order=manual` anywhere in the request. The stacking will follow the order you pass in parameters, with the first parameter being at the bottom.

  ##### Example

  If you want...

  - the eyes of [263a](https://unicode-table.com/en/263A) ☺️
  - the mouth of [2639](https://unicode-table.com/en/2639/) ☹️
  - the eyewear of [1f978](https://unicode-table.com/en/1F978/) 🥸

  <br>

  Your request will look like this:

  ```txt
  /faces/png?eyes=263a&mouth=2639&eyewear=1f978

  # Spaced out for easy reading
  /faces /png ? eyes=263a & mouth=2639 & eyewear=1f978
  ```

  If you want the eyes to be above the eyewear, add in `order=manual` and move eyes in front of eyewear:

  ```txt
  /faces/png?mouth=2639&eyewear=1f978&eyes=263a&order=manual

  # Spaced out for easy reading
  /faces /png ? mouth=2639 & eyewear=1f978 & eyes=263a & order=manual
  ```

- <details>
  <summary><b>Downloading</b></summary>
  <br>

  By default the output emoji is displayed. Pass in the key-value pair `download=true` anywhere in the request if you want a file to download instead.

  The default name of the file returned is a modified version of your request parameters. The equals signs (`=`) and ampersands (`&`) are replaced with a minus sign (`-`) and these characters `_-_`.

  ##### Example

  Request:

  ```txt
  /faces/png?eyes=263a&mouth=2639&eyewear=1f978&download=true
  ```

  File returned:

  ```txt
  eyes-263a_-_mouth-2639_-_eyewear-1f978.png
  ```

</details>

- <details>
  <summary><b>Filename</b></summary>
  <br>

  If you want to name your download file, pass in `filename=` with a value of your choosing.

  ##### Example

  Request:

  ```txt
  /faces/png?eyes=263a&mouth=2639&eyewear=1f978&download=true&filename=amazing_emoji.png
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
1. Run application locally: `ruby app/controllers/application_controller.rb`
1. Go to this URL in a browser to ensure it redirects to the [Custom Twemoji API GitHub repository](https://github.com/blakegearin/custom-twemoji-api): `http://localhost:4567`
1. Stop application: `CTRL + C`

## License

- Code licensed under [MIT License](LICENSE)
- Graphics licensed under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- Twemoji licensing can be found on [Twitter](https://twemoji.twitter.com)
