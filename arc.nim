# What a mess.
import strutils, os, times, json, htmlgen

let baseDir = "archive"
let logLoc = baseDir & "/log.json"

var cfg = parseJson(readFile("jfarc.json"))
var configChanged = false

let replaceCases = cfg["replaceCases"]
let replaceWith = cfg["replaceWith"].str

var internalVersion = getDateStr()

# Generates table entries for version
proc generateTds(t: JsonNode, v: string): string =
    result = ""
    for i in t:
        result &= tr(
            td(a(href=v & "/" & i["version"].str, i["version"].str)),
            td(
                if i.hasKey("description"): i["description"].str
                else: "Archive for " & i["version"].str
            )
        )

# Parses log.json
proc parseLog(): JsonNode = parseJson(readFile(logLoc))

# Creates archive/index.html
proc buildIndex(log: JsonNode) =
    var pageContent = ""

    for key, val in pairs(log["versions"]):
        pageContent &= h2("Version " & key) &
            " - " &
            a(href=key, "/" & key & "/") &
            table(generateTds(val, key))

    try:
        var page = readFile("jfarc.html")
        page = page.replace("*INSERT ARCHIVES HERE*", pageContent)
        writeFile(baseDir & "/index.html", page)
    except IOError:
        echo "Couldn't build index: ", getCurrentExceptionMsg()

# Creates a directory if it doesn't exist yet
proc crtDir(dir: string) =
    if not existsDir(dir):
        createDir(dir)

var thisVersion = newJObject()
#thisVersion["description"] = %"I am a sheep"

var files: seq[string]
files = @[]
let params = commandLineParams()
var i = 0
while i < params.len:
    var param = $params[i]
    if param.startsWith("--"):
        param.delete(0, 1)
        case param:
        of "setmajorversion":
            inc(i)
            cfg["version"].str = params[i]
            configChanged = true
        of "build-index":
            buildIndex(parseLog())
            echo "Succesfully build archive/index.html"
            quit()
        of "help":
            echo "oh snap"
            quit()
        else:
            discard
    elif param.startsWith("-"):
        param.delete(0, 0)
        case param:
        of "name":
            inc(i)
            internalVersion = params[i]
        of "description":
            inc(i)
            thisVersion["description"] = %params[i]
        else:
            discard
    else:
        files.add(param) #temp
    inc(i)

let version = cfg["version"].str
let subloc = baseDir & "/" & version
let loc = subloc & "/" & internalVersion & "/"

# Create neccesary directories
crtDir(baseDir)
crtDir(subloc)
crtDir(loc)

# Load log
var log: JsonNode

if fileExists(logLoc):
    log = parseLog()
else:
    log = newJObject()
    log["versions"] = newJObject()

# Add entry
thisVersion["version"] = %internalVersion

if not log["versions"].hasKey(version):
    log["versions"][version] = newJArray()

log["versions"][version].add(thisVersion)

# Filter URLs in files
for fileName in files:
    try:
        let dirs = fileName.split({'/'})
        var currentDir = loc
        for i in 0..dirs.len - 2:
            currentDir &= dirs[i]
            if not existsDir(currentDir):
                createDir(currentDir)

        var content = readFile(fileName)

        for k in replaceCases:
            content = content.replace(k.str & "/", replaceWith & k.str & "/")

        writeFile(loc & fileName, content)
    except IOError:
        echo "I/O error with file ", fileName, ": ", getCurrentExceptionMsg()

# Write to config if changed
if configChanged:
    writeFile("jfarc.json", pretty(cfg, 4))

# Write log
writeFile(logLoc, pretty(log, 4))

# Build the index file from the log
buildIndex(log)

echo "Succesfully archived to ", loc
