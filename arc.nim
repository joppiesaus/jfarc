# What a mess.
# I hope this isn't too bad.
import strutils, os, times, json, htmlgen

let baseDir = "archive"
let cfgName = "jfarc.json"
let logLoc = baseDir & "/log.json"

var cfg = parseJson(readFile(cfgName))
var configChanged = false

# Gets an string from jsonnode n, if it doesn't exist it'll return default
proc getjns(n: JsonNode, key, default: string): string =
    if n.hasKey(key):
        result = n[key].str
    else:
        result = default

# TODO: Create instead?
proc getCfg(key: string, default: JsonNode): JsonNode =
    if cfg.hasKey(key):
        result = cfg[key]
    else:
        echo cfgName, ": Key \"", key, "\" doesn't exist; assuming default ", $default
        result = default

let replaceCases = getCfg("replaceCases", %*["js", "lib", "dl"])
let replaceWith = getCfg("replaceWith", %*"/").str


var internalVersion = getDateStr()

# Generates table entries for version
proc generateTds(t: JsonNode, v: string): string =
    result = tr(th("Version"), th("Description"), th("Date"))
    for i in t:
        result &= tr(
            td(a(href=v & "/" & i["version"].str, i["version"].str)),
            td(i.getjns("description", "Acrhive for " & i["version"].str)),
            td(i.getjns("archive_time", "?"))
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
            table(generateTds(val, key) &
                tr(td(a(
                    href=key,
                    title="Use this as a permalink to go to the latest version of " & key & ".",
                    "Latest"
                )))
            )

    try:
        writeFile(baseDir & "/index.html", readFile("jfarc.html").replace("*INSERT ARCHIVES HERE*", pageContent))
    except IOError:
        echo "Couldn't build index: ", getCurrentExceptionMsg()

# Creates a directory if it doesn't exist yet
proc crtDir(dir: string) =
    if not existsDir(dir):
        createDir(dir)

# Creates a redirect index.html
proc createRedirFile(version, target: string) =
    let loc = baseDir & "/" & version & "/index.html"
    writeFile(loc, html(head(
        title("Redirecting you to " & target & "...") &
        "<meta charset=\"UTF-8\">" & #meta(charset="UTF-8") &
        "<meta http-equiv=\"refresh\" content=\"0; url=" & target & "\">") #meta(http-equiv="refresh", content="5;url=" & target))
    ) & body(
        p("Redirecting you to the latest version of " & version & "(" & target & "). " &
        a(href=target,"Click here") & " if that doesn't happen.")
    ))

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
            echo paramStr(0), " - archives things"
            echo "Options:"
            echo "\t--setmajorversion <version> - Sets the current major version"
            echo "\t--build-index - Rebuilds archive index file based on log.json"
            echo "\t-name <name> - Set current archive's name"
            echo "\t-description <description> - Sets current archive's description"
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

if cfg.hasKey("files"):
    for glob in cfg["files"]:
        for path in walkFiles(glob.str):
            files.add(path)

if files.len < 1:
    echo "No input files specified; aborting"
    quit()

let version = getCfg("version", %*"1").str
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
thisVersion["archive_time"] = %(getDateStr() & " " & getClockStr())

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
    writeFile(cfgName, pretty(cfg, 4))

# Write log
writeFile(logLoc, pretty(log, 4))

# Write redirect file
createRedirFile(version, internalVersion)

# Build the index file from the log
buildIndex(log)

echo "Succesfully archived to ", loc
