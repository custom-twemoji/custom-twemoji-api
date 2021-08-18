# Twemoji Mashup API

## Endpoints

- `/xml`
- `/svg`
- `/png`

## Parameters

### Basics

The face parts, listed in the default stacking order, can be found at the top of [app.rb](app.rb#L5-L13). You can specify an emoji for each part you want to include, and leave off parts you don't care about.

#### Example

If you want...

- the cheeks of 263a ☺️
- the mouth of 2639 ☹️
- the eyewear of 1f978 🥸

Your request will look like this:

```txt
?cheeks=263a&mouth=2639&eyewear=1f978
```

### Advanced

If you want to specify your own stacking order, pass in `order=manual` anywhere in the request. The order of the rest of your parameters will be how the output is stacked, with the first parameter being at the bottom.
