#!/usr/bin/env python3
#  MIT License
#
#  (C) Copyright [2024] Hewlett Packard Enterprise Development LP
#
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.

#If we ever need to go directly to s3; here is its endpoint
#S3_ENDPOINT=$(kubectl -n services get secrets fw-update-s3-credentials -o json | jq -r '.data.s3_endpoint' | base64 -d)

import json
import subprocess as sp
import os

errors=0

print("Attempting to retrieve Foxconn images")

image_files=sp.getoutput("cray fas images list --format json")
imagejson=json.loads(image_files)
for image in imagejson["images"]:
  if image["manufacturer"] == "foxconn":
    if "s3URL" in image:
      s3url = image["s3URL"]
      url = s3url.split("/")
      # url could be something other than s3, but so far only s3 is supported
      if url[0] == "s3:":
        if len(url) > 3:
          bucket = ""
          path = ""
          filename = ""
          # Find the filename, path, and s3 bucket
          for name in url:
            # Bucket is always fw-update
            if name == "fw-update":
              bucket = name
            elif bucket != "":
              if len(path) > 0:
                path = path + "/"
              path = path + name
            filename = name
        tmpfilename = "/tmp/" + filename
        print("cray artifacts get " + bucket + " " + path + " " + tmpfilename)
        os.system("cray artifacts get " + bucket + " " + path + " " + tmpfilename)
        print("cray-tftp-upload " + tmpfilename)
        os.system("cray-tftp-upload " + tmpfilename)
        print("rm " + tmpfilename)
        os.system("rm " + tmpfilename)
        if "tftpURL" not in image:
          imageid = image["imageID"]
          print("Updating " + imageid + " in FAS")
          image["tftpURL"] = "tftp://" + filename
          print(image)
          tmpfilename = "/tmp/" + imageid + ".json"
          with open(tmpfilename, "w") as outfile:
              jsonimage = json.dumps(image)
              outfile.write(jsonimage)
          os.system("cray fas images update " + tmpfilename + " " + imageid)
          os.system("rm " + tmpfilename)
    else:
      print("------")
      print("ERROR: s3URL not found in image")
      print(image)
      print("------")
