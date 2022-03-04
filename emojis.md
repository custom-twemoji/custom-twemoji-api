## :slightly_smiling_face: All Twemojis

- `GET /v1/emojis`
  - Returns JSON list of all supported faces
- `GET /v1/faces/layers`
  - Returns JSON list of all supported faces and each layer corresponding to a facial feature
- `GET /v1/faces/features`
  - Returns JSON list of all supported faces with each facial feature and their corresponding layer(s)
- `GET /v1/faces/random`
  - Default is 100% chance of having a head but 50% for all other features
  - Customize feature probability by passing in a Boolean (true or false) or decimal number between 0 and 1 (e.g. `/v1/faces/random?eyes=0.75&nose=false` has a 75% chance of having eyes and 0% for nose)
- `GET /v1/faces/{emoji}`
  - Build a custom face starting with a base emoji
  - Valid emoji formats:
    - glyph: 🙂
    - case insensitive codepoint: `1f642` or `U+1f642`
    - number representation `128578`

### Defaults

- Output: JSON
- Emoji is returned as an SVG under `resource`
- Licensing information is included

Example response with defaults:

  ```json
  {
    "success": true,
    "data": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100%\" height=\"100%\" viewBox=\"0 0 36 36\">\n<circle fill=\"#FFCC4D\" cx=\"18\" cy=\"18\" r=\"18\" id=\"1f61e-head\" class=\"1f61e-head\"/><path d=\"M18 24.904C11 24.904 9 22.286 9 23.523 9 24.762 13 28 18 28S27 24.762 27 23.523C27 22.286 25 24.904 18 24.904\" fill=\"#292F33\" id=\"1f31a-mouth\" class=\"1f31a-mouth\"/><path fill=\"#DD2E44\" d=\"M17.179 2.72C17.136 2.6710000000000003 17.069 2.644 16.99 2.629 16.99 2.629 1.065999999999999-0.39400000000000013 0.3769999999999989 0.21399999999999997-0.311 0.823 0.74 16.998 0.74 16.998 0.745 17.079 0.763 17.148 0.8069999999999999 17.197000000000003 1.411 17.881000000000004 5.5649999999999995 15.193000000000003 10.086 11.196000000000002 14.608 7.198000000000001 17.783 3.4040000000000017 17.179000000000002 2.7200000000000006Z\" id=\"1f973-headwear\" class=\"1f973-headwear\"/><path fill=\"#EA596E\" d=\"M0.349 0.271C0.334 0.301 0.321 0.342 0.311 0.394 0.47 1.765 2.006 13.046 2.963 16.572 4.399 15.768999999999998 5.8580000000000005 14.677999999999999 7.572 13.318999999999999 6.116 10.654 1.158 0.146 0.349 0.271Z\" id=\"1f973-headwear1\" class=\"1f973-headwear\"/><path fill=\"#5DADEC\" d=\"M11 11C11 13.762 8.762 16 6 16 3.239 16 1 13.762 1 11S5 1 6 1 11 8.238 11 11Z\" id=\"1f613-other\" class=\"1f613-other\"/></svg>",
    "license": {
      "name": "CC-BY 4.0",
      "url": "https://creativecommons.org/licenses/by/4.0"
    }
  }
  ```

### URL Parameters

After the endpoint, you can add a question mark (`?`) and pass in URL parameters as key-value pairs (`key=value`) separated by ampersands (`&`).

```txt
GET /v1/faces/{emoji}?key1=value1&key2=value2
```

- <details>
  <summary><b>Facial Features</b></summary>
  <br>

  Facial feature are passed in as keys with emojis as their values.

  Each feature is a layer and the order in which they're stacked impacts what will be seen or hidden in its final visual form. This is the list of features in default stacking order from bottom to top.

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
  /v1/faces/1f47f?eyes=263a&mouth=2639&eyewear=1f978

  # Spaced out for easy reading
  /v1/faces /1f47f ? eyes=263a & mouth=2639 & eyewear=1f978
  ```

  A base emoji is required, but you can exclude any feature by passing in the parameter as `false` or empty:

  ```txt
  # Head empty, no thoughts
  /v1/faces/1f47f?head=&mouth=2639

  # Spaced out for easy reading
  /v1/faces /1f47f ? head= & mouth=2639

  # Head false, headless horseman!
  /v1/faces/1f47f?head=false&mouth=2639

  # Spaced out for easy reading
  /v1/faces /1f47f ? head=false & mouth=2639
  ```

  If you want the eyes to be above the eyewear, add in `order=manual` and move eyes in front of eyewear:

  ```txt
  /v1/faces/1f47f?mouth=2639&eyewear=1f978&eyes=263a&order=manual

  # Spaced out for easy reading
  /v1/faces /1f47f ? mouth=2639 & eyewear=1f978 & eyes=263a & order=manual
  ```

</details>

- <details>
  <summary><b>Output</b></summary>
  <br>

  Options:
  <br>

  - JSON (`output=json`)
  - image (`output=image`)
  - download (`output=download`)
    - The default name of the file returned is the emoji described in key-value pairs
    - The equals signs (`=`) and ampersands (`&`) are replaced with a minus sign (`-`) and these characters `_-_`
    - If you want to name your download file, pass in `filename=` with a value of your choosing.

      Example Request:

      ```txt
      /v1/faces/263a?file_format=png&download=true&filename=amazing_emoji
      ```

      File returned: `amazing_emoji.png`

</details>

- <details>
  <summary><b>File Formats</b></summary>

  ### SVG (`file_format=svg`)

  Defaults:

  - Output:
    - JSON: XML
    - Image: MIME type of `image/png`
  - Size: `100%`
  - Padding: `0px`

  ### PNG (`file_format=png`)

  Defaults:

  - Output:
    - JSON: [Base64](https://developer.mozilla.org/en-US/docs/Glossary/Base64)
    - Image: MIME type of `image/png`
  - Size: `128px` (ideal for Slack)
  - Padding: `0px`
  - Renderer:
    - `imagemagick` for `json` and `download`
    - `canvg` for `image`

</details>

- <details>
  <summary><b>Color, Sizing, and Padding</b></summary>

  ### Color (`background_color=red`)

  Specify a background color with a string. Formats supported:

  - [HTML color names](https://www.w3schools.com/colors/colors_hex.asp)
  - escaped hexadecimal values  (e.g. `#bbbbbb` escaped is `%23bbbbbb`)
  - escaped RGB/RGBA values (e.g. `rgb(100%, 0%, 0%)` escaped is `rgb%28100%25%2C%200%25%2C%200%25%29`)
  - escaped HSL/HSLA values (e.g. `hsl(120, 50%, 50%)` escaped is `hsl%28120%2C%2050%25%2C%2050%25%29`)

  ### Sizing (`size=500`)

  Specify the size of the output in pixels with an integer. It will always be a square so height and width are equal.

  ### Padding (`padding=100`)

  Add padding between the emoji and the edge of the output. Specify the number of pixels of the padding with an integer. This reduces the size of the emoji, but not the `size` of the output.

</details>
