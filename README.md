This is a program that is made to archive websites without cloning all resources.

It's not finished, and I don't know about the quality of it, but for me, it works. I made this for my own website, but this is pretty stupid since I use git as version control so I can always check out how it was at a certain date/commit.

# Building
`nim c -d:release arc.nim`

# Setting up
To get the archiver working for your website, you need to configure some things.
You'll need to create two files: `jfarc.json`, the configuration file that contains information about how jfarc should archive your website, and `jfarc.html`, the index file that will be used as a place to explore your archives.

This is a sample `jfarc.json`:
```json
{
    "version": "1",
    "files": [
        "index.html", "js/*.js", "css/*.css"
    ],
    "replaceCases": [
        "img",
        "dl",
        "lib"
    ],
    "replaceWith": "/"
}
```

`version` will specify what major version your current website is. Your website mutates over time, but if something  big changes(i.e. a new website from scratch), you could change this to another value.

`files` is an array of GLOB strings to look for files you want to archive.

`replaceCases` is an array of strings - usually URI's - that need to be modified inside your files to get the website working on a different location. It will be concat with `replaceWith`. Let's say you have `example.com`. You want to archive `index.html` to the folder `archive/1/myarchive`, but you have images, in `example.com/img`. Then you could add `img` to `replaceCases`, and then set `replaceWith` to `/`. This replaces all `img/` to `/img/` in `index.html`(i.e. `img/ball.png` becomes `/img/ball.png`).

Then you have `jfarc.html`:
```html
<!DOCTYPE html><html>
<head>
    <title>Archive!</title>
    <style>
    table
    {
        margin-left: 2em;
    }
    table, th, td
    {
        border: 1px solid #000;
        border-collapse: collapse;
    }
    </style>
</head>
<body>
    <h1>Archive!</h1>
*INSERT ARCHIVES HERE*
</body></html>
```

This will be the `archive/index.html` file where you can see all versions and it's links.
The `*INSERT ARCHIVES HERE*` will be replaced by the archive html.

# Using
`./arc [-name <name>] [-description <description>]`

This will generate an archive configured by you in `archive/<version>/<name>/`
If `name` not specified it'll use the current date.

Execute `./arc --help` for more options, or just browse the source code ;)
