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

# the raw string if a 200
# None if a 404
# otherwise, panics
def fetch(url):
    print("fetching " + url)
    url = addApiKey(apiKey, url)
    try:
        return urllib.request.urlopen(url).read().decode("utf-8")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print("404 for url " + url)
            return None
        else:
            raise e


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
        newData = fetch(url)

        quotes = file.readline()
        assert quotes == " " * 16 + "\"\"\"\n"
        newLines.append(quotes)

        oldData = file.readline()
        if newData:
            newData = newData.replace("\\", "\\\\") # in polylines, escape them so they can be in Elm strings
            newLines.append(" " * 16 + newData + "\n")
        else:
            newLines.append(oldData)

        quotes = file.readline()
        assert quotes == " " * 16 + "\"\"\"\n"
        newLines.append(quotes)
