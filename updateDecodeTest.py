# DecodeTest.elm has a bunch of json saved from API calls.
# This script calls all the endpoints in the file and updates their saved JSON
# Some endpoints depend on what vehicles or trips are in service, so you may need to change some ids.
# Takes an api key as an optional argument

import urllib.request
import sys

if len(sys.argv) > 1:
    apiKey = sys.argv[1]
else:
    apiKey = None

def addApiKey(apiKey, url):
    if apiKey != None:
        if "?" in url:
            if url.endswith("?"):
                return url + "api_key=" + apiKey
            else:
                return url + "&api_key=" + apiKey
        else:
            return url + "?api_key=" + apiKey
    else:
        return url

def fetch(url):
    url = addApiKey(apiKey, url)
    return urllib.request.urlopen(url).read().decode("utf-8")


filename = "tests/Mbta/DecodeTest.elm"
file = open(filename, "r")

newLines = []


while True:
    line = file.readline()
    if not line:
        # reached end of file
        file.close()
        file = open(filename, "w")
        file.writelines(newLines)
        file.close()
        exit()
    newLines.append(line)
    if line.startswith(" " * 16 + "\"http"):
        url = line[17:-2]
        print("fetching " + url)
        quotes = file.readline()
        assert quotes == " " * 16 + "\"\"\"\n"
        newLines.append(quotes)
        newData = fetch(url)
        newData = newData.replace("\\", "\\\\") # in polylines, escape them so they can be in Elm strings
        oldData = file.readline()
        newLines.append(" " * 16 + newData + "\n")
