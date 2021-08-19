# Twemoji Mashup API

## Faces (`GET /faces`)

### Endpoints

The available endpoints correspond to the supported file formats.

- [XML](https://www.w3schools.com/XML/xml_whatis.asp): `/xml`
- [SVG](https://www.w3schools.com/graphics/svg_intro.asp): `/svg`
- [PNG](https://www.lifewire.com/png-file-2622803): `/png`

### URL Parameters

Pass in a parameter for each facial feature you want to add as a key-value pair (`?key=value`) separated by an ampersand (`&`).

- Key: facial feature
- Value: emoji

#### Facial Features

1. head
1. headwear
1. cheeks
1. mouth
1. nose
1. eyes
1. eyewear
1. other

Each feature is a layer and the order in which they're stacked impacts what is seen or hidden. This is the stacking order from bottom to top.

#### Example

If you want...

- the cheeks of [263a](https://unicode-table.com/en/263A) ☺️
- the mouth of [2639](https://unicode-table.com/en/2639/) ☹️
- the eyewear of [1f978](https://unicode-table.com/en/1F978/) 🥸

Your request will look like this:

```txt
?cheeks=263a&mouth=2639&eyewear=1f978
```

#### Customize

If you want to specify your own stacking order, pass in `order=manual` anywhere in the request. The order of the rest of your parameters will be how the output is stacked, with the first parameter being at the bottom.
