#!/usr/bin/python3

# MIT License
#
# (C) Copyright [2021-2023] Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.


import sys,getopt
import json
from base64 import b64decode
import requests
from kubernetes import client, config

dryrun = False
debugLevel = 0


# Create a k8s client object for use in getting auth tokena.

def getK8sClient():
	config.load_kube_config()
	k8sClient = client.CoreV1Api()
	return k8sClient


# Fetch auth token for HMS REST API calls.

def getAuthenticationToken():
	URL = "https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token"

	kSecret = getK8sClient().read_namespaced_secret("admin-client-auth", "default")
	secret = b64decode(kSecret.data['client-secret']).decode("utf-8")

	DATA = {
		"grant_type": "client_credentials",
		"client_id": "admin-client",
		"client_secret": secret
	}

	try:
		r = requests.post(url=URL, data=DATA)
	except OSError:
		return ""

	result = json.loads(r.text)
	return result['access_token']


# Func to get a JSON payload from a URL.  It's assumed to be a full URL.
# Also note that we'll only ever be contacting HMS services.

def doRest(uri, authToken, postPayload=None):
	global dryrun
	global debugLevel

	if not postPayload:
		# GET
		hdrs = {'Authorization': 'Bearer %s' % authToken,}
		r = requests.get(url=uri, headers=hdrs)
	else:
		# POST
		hdrs = {'Authorization': 'Bearer %s' % authToken, 'Content-Type': 'application/json',}
		if debugLevel > 2:
			print("URL: '%s', headers: '%s', payload: '%s'" % (uri,hdrs,postPayload))

		if dryrun == False:
			r = requests.post(url=uri, headers=hdrs, data=postPayload)
		else:
			fakeret = {'Targets': [{'Xname':'all','StatusCode':200,'StatusMsg': 'OK'}]
			}
			return json.dumps(fakeret), 0

	retJSON = r.text

	if r.status_code >= 300:
		ret = 1
	else:
		ret = 0

	return retJSON, ret


# Fetch all components in HSM

def getHSMComponents(authToken):
	url = "https://api-gw-service-nmn.local/apis/smd/hsm/v2/State/Components"
	compsJSON, rstat = doRest(url, authToken)
	return compsJSON, rstat


# Get RF endpoints from HSM.

def getHSMRFEPs(authToken):
	url = "https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/RedfishEndpoints"
	rfepsJSON, rstat = doRest(url, authToken)
	return rfepsJSON, rstat


# Get the root SSH public key.

def getRootSSHKey():
	fname = '/root/.ssh/id_rsa.pub'
	emsg = None
	try:
		f = open(fname, 'r')
	except FileNotFoundError:
		emsg = "File not found: %s" % fname
	except PermissionError:
		emsg = "Permission denied: %s" % fname

	if emsg:
		print(emsg)
		return None

	data = f.read()
	return data


# Print usage info

def usage():
	print("Usage: %s [options]" % sys.argv[0])
	print(" ")
	print("   --debug=level    Set debug level")
	print("   --dryrun         Gather all info but don't set anything in HW.")
	print("   --exclude=list   Comma-separated list of target patterns to exclude.")
	print("                    Each item in the list is matched on the front")
	print("                    of each target XName and excluded if there is a match.")
	print("                    Example: x1000,x3000c0,x9000c1s0")
	print("                        This will exclude all BMCs in cabinet x1000,")
	print("                        all BMCs at or below x3000c0, and all BMCs")
	print("                        below x9000c1s0.")
	print("                    NOTE: --include and --exclude are mutually exclusive.")
	print("   --include=list   Comma-separated list of target patterns to include.")
	print("                    Each item in the list is matched on the front")
	print("                    of each target XName and included is there is a match.")
	print("                    NOTE: --include and --exclude are mutually exclusive.")
	print("   --sshkey=key     SSH key to set on BMCs.  If none is specified, will use")
	print("                    the root account SSH public key.")
	print(" ")

def errorGuidance():
	print(" ")
	print("For troubleshooting and manual steps, see https://github.com/Cray-HPE/docs-csm/blob/main/troubleshooting/BMC_SSH_key_manual_fixup.md.")
	print(" ")


def main():
	global dryrun
	global debugLevel

	# First get exclude list, if any

	rootSSHKey = None
	excludeList = None
	includeList = None
	excludes = []
	includes = []

	try:
		opts,args = getopt.getopt(sys.argv[1:],"",["exclude=","include=","debug=","dryrun","sshkey="])
	except getopt.GetoptError:
		usage()
		return 1

	for opt,arg in opts:
		if opt == '-h':
			usage()
			return 0
		elif opt in ("--exclude"):
			excludeList = arg
		elif opt in ("--include"):
			includeList = arg
		elif opt in ("--dryrun"):
			dryrun = True
		elif opt in ("--debug"):
			debugLevel = int(arg)
		elif opt in ("--sshkey"):
			rootSSHKey = arg

	if not includeList == None and not excludeList == None:
		print("ERROR: Can't use both --exclude and --include.")
		return 1

	if not includeList == None:
		includes = includeList.split(',',-1)

	if not excludeList == None:
		excludes = excludeList.split(',',-1)

	if debugLevel > 0:
		print("Excludes: .%s." % excludes)
		print("Includes: .%s." % includes)

	authToken = getAuthenticationToken()
	if authToken == "":
		print("ERROR: No/empty auth token, can't continue.")
		print(" ")
		print("For troubleshooting and manual steps, see https://github.com/Cray-HPE/docs-csm/blob/main/operations/security_and_authentication/Retrieve_an_Authentication_Token.md.")
		print(" ")
		return 1

	if not rootSSHKey:
		rootSSHKey = getRootSSHKey()
		if not rootSSHKey:
			print("ERROR: Can't get root SSH key.")
			errorGuidance()
			return 1

	# Get all discovered mountain BMCs -- ChassisBMCs, NodeBMCs, RouterBMCs.
	# Get this info from the State/Components API in HSM.  Also get RF
	# endpoint info.

	compRaw,stat = getHSMComponents(authToken)
	if stat != 0:
		print("HSM Component fetch returned non-zero.")
		errorGuidance()
		return 1

	rfepRaw,stat = getHSMRFEPs(authToken)
	if stat != 0:
		print("HSM RF Endpoint fetch returned non-zero.")
		errorGuidance()
		return 1

	# Generate a JSON payload for SCSD.

	compJSON = json.loads(compRaw)
	rfepJSON = json.loads(rfepRaw)
	ids = []

	# First get a list of mountain/hill BMCs.  Make sure there is an RFEP for
	# each one or it won't be valid.

	for comp in compJSON['Components']:
		if debugLevel > 2:
			print("COMP: .%s." % comp)

		if len(excludes) > 0:
			skip = False
			for excl in excludes:
				if comp['ID'].startswith(excl):
					skip = True
					break
			if skip == True:
				continue

		if len(includes) > 0:
			skip = True
			for incl in includes:
				if comp['ID'].startswith(incl):
					skip = False
					break
			if skip == True:
				continue

		lcmp = None
		tclass = None

		# Some components have no class at all.  Rubes!  Try to infer it.

		if "Class" in comp:
			tclass = comp['Class']
		else:
			if comp['Type'] == "CabinetPDUController" or comp['Type'] == "CabinetPDUPowerConnector":
				tclass = "River"
			else:
				if debugLevel > 2:
					print("WARNING: component with no class, ignoring: '%s', type: '%s'" % (comp['ID'],comp['Type']))
				continue


		if tclass == "Mountain" or tclass == "Hill":
			if comp['Type'] == "ChassisBMC" or comp['Type'] == "NodeBMC" or comp['Type'] == "RouterBMC":
				lcmp = comp['ID']
		else:
			if comp['Type'] == "RouterBMC":
				lcmp = comp['ID']

		if not lcmp == None:
			if debugLevel > 2:
				print("MATCHED: '%s'" % lcmp)

			# Get FQDN from RFEP data
			lf = list(filter(lambda rfid: rfid['ID'] == lcmp, rfepJSON['RedfishEndpoints']))
			if len(lf) == 0:
				print("WARNING: RF endpoint for '%s' not found, ignoring." % lcmp)
			else:
				ids.append(lcmp)

	if len(ids) == 0:
		print("No mountain-class BMCs found, nothing to do.")
		return 0

	# Use the list of BMCs to create an SCSD payload.

	pld = {
		'Targets': ids,
		'Params': {'SSHKey': rootSSHKey.rstrip()}
	}

	# Use SCSD to set SSH keys on all of these controllers.   Create a JSON
	# payload to cover all of them and use the /bmc/globalcreds API.

	url = "https://api_gw_service.local/apis/scsd/v1/bmc/loadcfg"
	rfepJSON, rstat = doRest(url, authToken, json.dumps(pld))

	# Check the returned JSON payload to see if any targets failed, and if so,
	# report them.  Any error results in a script failure.

	if rstat != 0:
		print("Setting SSH keys failed: %s" % rfepJSON)
		errorGuidance()
		return 1

	rval = 0
	rj = json.loads(rfepJSON)
	for tgt in rj['Targets']:
		if tgt['StatusCode'] >= 300:
			print("Failed to set SSH keys on %s: %s" % (tgt['Xname'],tgt['StatusMsg']))
			rval = 1

	if rval != 0:
		errorGuidance()

	return rval


if __name__ == "__main__":
	ret = main()
	exit(ret)
