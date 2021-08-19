# Twemoji Mashup API

An API that let's you combine [Twitter's emojis](https://twemoji.twitter.com/).

## Faces (`GET /faces`)

### Endpoints

The available endpoints correspond to the supported file formats.

- [SVG](https://www.w3schools.com/graphics/svg_intro.asp): `/svg`
- [PNG](https://www.lifewire.com/png-file-2622803): `/png`

### URL Parameters

Passed in as key-value pairs (`?key=value`) separated by an ampersand (`&`).

- <details>
  <summary><b>Facial Features</b></summary>
  <br>

    - Key: facial feature
    - Value: emoji

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
