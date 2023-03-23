#!/usr/bin/python3

# MIT License
#
# (C) Copyright [2023] Hewlett Packard Enterprise Development LP
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

"""
	Attempt to rearrange NIDs for specified nodes to create a numerically (NID)
	and lexicographically (xname) contiguous block of NIDs at the specified start.
	
	This script makes a few assumptions:
	1) Inventory data is up to date (nothing has changed since the last HSM discovery).
	2) Chassis entries in SLS are correct and exist for all Mountain and Hill hardware.
	3) HSM's view of nodes is more correct than SLS's and will delete SLS entries with
	   conflicting NIDs and create new SLS entries for nodes found by HSM that are not
	   in SLS.
	4) HSM may have node information for non-existent nodes left behind by a blade swap
	   where procedure wasn't followed. The script will delete these.
"""

import json
from base64 import b64decode
import sys,getopt
import requests
from kubernetes import client, config

hsmURL = "https://api-gw-service-nmn.local/apis/smd/hsm/v2"
slsURL = "https://api-gw-service-nmn.local/apis/sls/v1"

dryrun = False
debugLevel = 0
outputFormat = "json"
simMode = False

# MaxComponentQuery is the maximum number of components that we can safely allow
# in URI parameters before it might get too long for some buffer somewhere.
MaxComponentQuery = 2048

def getK8sClient():
	"""Create a k8s client object for use in getting auth tokens."""
	config.load_kube_config()
	k8sClient = client.CoreV1Api()
	return k8sClient

def getAuthenticationToken():
	"""Fetch auth token for HMS REST API calls."""
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

def doRest(uri, authToken, op, payload=None):
	"""
		Func to get a JSON payload from a URL. It's assumed to be a full URL.
		Also note that we'll only ever be contacting HMS services.
	"""
	restHeaders = {}
	if not simMode:
		restHeaders['Authorization'] = 'Bearer %s' % authToken
	if op == "get":
		r = requests.get(url=uri, headers=restHeaders)
	elif op == "delete":
		r = requests.delete(url=uri, headers=restHeaders)
	elif op == "post" and not payload is None:
		r = requests.post(url=uri, headers=restHeaders, data=json.dumps(payload))
	elif op == "put" and not payload is None:
		r = requests.put(url=uri, headers=restHeaders, data=json.dumps(payload))
	elif op == "patch" and not payload is None:
		r = requests.patch(url=uri, headers=restHeaders, data=json.dumps(payload))
	else:
		return 1

	retJSON = r.text

	if r.status_code >= 300:
		stat = 1
	else:
		stat = 0

	respData = None
	if len(retJSON) > 2:
		respData = json.loads(retJSON)
	return respData, stat

def doRestGet(uri, authToken):
	"""Wrapper for doRest() for GET operations"""
	return doRest(uri, authToken, "get")

def doRestPost(uri, authToken, payload):
	"""Wrapper for doRest() for POST operations"""
	return doRest(uri, authToken, "post", payload)

def doRestPatch(uri, authToken, payload):
	"""Wrapper for doRest() for PATCH operations"""
	return doRest(uri, authToken, "patch", payload)

def doRestPut(uri, authToken, payload):
	"""Wrapper for doRest() for PUT operations"""
	return doRest(uri, authToken, "put", payload)

def doRestDelete(uri, authToken):
	"""Wrapper for doRest() for DELETE operations"""
	return doRest(uri, authToken, "delete")

def getHSMComps(authToken, fltr):
	"""Get HSM Component data"""
	url = hsmURL + "/State/Components" + fltr
	return doRestGet(url, authToken)

def getHSMCompQuery(authToken, compFilter):
	"""Expand a list of components based on a filter"""
	url = hsmURL + "/State/Components/Query"
	return doRestPost(url, authToken, compFilter)

def getHSMRFEndpoints(authToken, fltr):
	"""Get RedfishEndpoint information from HSM"""
	url = hsmURL + "/Inventory/RedfishEndpoints" + fltr
	return doRestGet(url, authToken)

def getHSMHWInv(authToken, xname, fltr):
	"""Get hardware inventory information from HSM"""
	url = hsmURL + "/Inventory/Hardware/Query/" + xname + fltr
	return doRestGet(url, authToken)

def patchHSMNIDs(authToken, nidList):
	"""Update component NID information in HSM"""
	url = hsmURL + "/State/Components/BulkNID"
	payload = {
		'Components': nidList
	}
	return doRestPatch(url, authToken, payload)

def patchHSMClass(authToken, hmsClass, compList):
	"""Update component NID information in HSM"""
	url = hsmURL + "/State/Components/BulkClass"
	payload = {
		'ComponentIDs': compList,
		'Class': hmsClass
	}
	return doRestPatch(url, authToken, payload)

def deleteHSMComp(authToken, xname):
	"""Delete HSM component data"""
	url = hsmURL + "/State/Components/" + xname
	return doRESTDelete(url, authToken)

def deleteHSMCompEP(authToken, xname):
	"""Delete HSM component endpoint data"""
	url = hsmURL + "/Inventory/ComponentEndpoints/" + xname
	return doRESTDelete(url, authToken)

def deleteHSMHwLoc(authToken, xname):
	"""Delete HSM hardware location data (detach FRU data from the empty location)"""
	url = hsmURL + "/Inventory/Hardware/" + xname
	return doRESTDelete(url, authToken)

def getHSMEth(authToken, fltr):
	"""Get HSM ethernet interfaces data"""
	url = hsmURL + "/Inventory/EthernetInterface" + fltr
	return doRestGet(url, authToken)

def deleteHSMEth(authToken, id):
	"""Delete HSM ethernet interface data"""
	url = hsmURL + "/Inventory/EthernetInterface/" + id
	return doRESTDelete(url, authToken)

def postHSMComps(authToken, compList):
	"""Expand a list of components based on a filter"""
	url = hsmURL + "/State/Components"
	payload = {
		'Components': compList,
		'force': True
	}
	return doRestPost(url, authToken, payload)

def getChassisClass(authToken, chassis):
	"""Get the hardware class of the specified chassis from SLS"""
	slsComps, stat = getSLSComps(authToken, "?xname=" + chassis)
	if stat != 0:
		return slsComps, stat
	if slsComps == None or slsComps == "":
		return "River", stat
	return slsComps[0]['Class'], stat

def getSLSComps(authToken, fltr):
	"""Get component information from SLS"""
	url = slsURL + "/search/hardware" + fltr
	return doRestGet(url, authToken)

def putSLSComp(authToken, slsEntry):
	"""Update/Create component entries in SLS"""
	url = slsURL + "/hardware/" + slsEntry['Xname']
	return doRestPut(url, authToken, slsEntry)

def deleteSLSComp(authToken, xname):
	"""Delete a component from SLS"""
	url = slsURL + "/hardware/" + xname
	return doRestDelete(url, authToken)

def compSort(comp):
  return comp['ID']

def printReport(report):
	if outputFormat == "text":
		printReportText(report)
	else:
		printReportJson(report)

def printReportText(report):
	"""Print a text report comparing what was with what will be."""
	print(report['Description'])
	print("=================")
	print("Starting NID: %d" % report['StartingNID'])
	print("Include: %s" % report['Include'])
	print("=================")
	print("HSM Changes:")
	for node in report['HSMChanges']:
		print("%s %d -> %d" % (node['ID'], node['OldNID'], node['NewNID']))
	print("")
	print("SLS Entries:")
	for entry in report['SLSEntries']:
		print(json.dumps(entry))
	if len(report['NodesRemovedFromHSM']) > 0:
		print("")
		print("Nodes Removed From HSM:")
		print("    " + ','.join(report['NodesRemovedFromHSM']))
	if len(report['NodesRemovedFromSLS']) > 0:
		print("")
		print("Nodes Removed From SLS:")
		print("    " + ','.join(report['NodesRemovedFromSLS']))
	if len(report['Errors']) > 0:
		print("")
		print("Errors:")
		for err in report['Errors']:
			if 'IDs' in err:
				print("%s: %s - IDs: %s" % (err['Severity'], err['Message'], ','.join(err['IDs'])))
			else:
				print("%s: %s" % (err['Severity'], err['Message']))

def printReportJson(report):
	"""Print a JSON report comparing what was with what will be."""
	print(json.dumps(report))

def usage():
	print("Usage: %s [options]" % sys.argv[0])
	print(" ")
	print("   --debug=level    Set debug level")
	print("   --dryrun         Gather all info but don't change anything.")
	print("   --start=NID      The desired starting point for the new block of NIDs.")
	print("   --include=list   Comma-separated list of XNames. This list will be expanded")
	print("                    to a list of compute nodes to act upon.")
	print("                    Example: --include=x1000 includes all compute nodes in cabinet x1000.")
	print("   --output=format  Format of the output. The options are:")
	print("                      - json (default)")
	print("                      - text")
	print("   --ignore-discovery-errors  Specify to ignore HSM discovery errors.")
	print("   --sim-mode       Specify to run in a simulation environment without kubernetes auth.")
	print(" ")

def main():
	"""Entry point"""
	global dryrun
	global debugLevel
	global outputFormat
	global simMode
	global hsmURL
	global slsURL

	startingNID = None
	includeList = None
	includes = []
	ignoreDiscoveryErrors = False
	errors = []
	report = {
		'Description': 'NID Defragmentation Report',
		'StartingNID': 1,
		'Include': [],
		'HSMChanges': [],
		'SLSEntries': [],
		'NodesRemovedFromHSM': [],
		'NodesRemovedFromSLS': [],
		'Errors': []
	}

	try:
		opts,args = getopt.getopt(sys.argv[1:],"",["start=","include=","debug=","dryrun","output=","ignore-discovery-errors","sim-mode"])
	except getopt.GetoptError:
		usage()
		return 1

	for opt,arg in opts:
		if opt == '-h':
			usage()
			return 0
		elif opt in ("--start"):
			startingNID = int(arg)
		elif opt in ("--include"):
			includeList = arg
		elif opt in ("--dryrun"):
			dryrun = True
		elif opt in ("--debug"):
			debugLevel = int(arg)
		elif opt in ("--output"):
			if arg == "text":
				outputFormat = arg
			else:
				outputFormat = "json"
		elif opt in ("--ignore-discovery-errors"):
			ignoreDiscoveryErrors = True
		elif opt in ("--sim-mode"):
			simMode = True
			hsmURL = "http://localhost:27779/hsm/v2"
			slsURL = "http://localhost:8376/v1"

	if startingNID == None:
		startingNID = 1

	if not includeList == None:
		includes = includeList.split(',',-1)

	report['StartingNID'] = startingNID
	report['Include'] = includes

	authToken = ""
	if not simMode:
		authToken = getAuthenticationToken()
		if authToken == "":
			err = {
				'Message': 'No/empty auth token, cannot continue. For troubleshooting and manual steps, see https://github.com/Cray-HPE/docs-csm/blob/main/operations/security_and_authentication/Retrieve_an_Authentication_Token.md.',
				'Severity': 'Error'
			}
			report['Errors'].append(err)
			printReport(report)
			return 1

	compFilter = {
		'ComponentIDs': includes,
		'type': ['Node'],
		'role': ['Compute']
	}

	# Expand to a list of nodes
	nodes, stat = getHSMCompQuery(authToken, compFilter)
	if stat != 0:
		err = {
			'Message': 'HSM Components Query returned non-zero. %s' % nodes,
			'Severity': 'Error'
		}
		report['Errors'].append(err)
		printReport(report)
		return 1

	# Get the RedfishEndpoint data for the NodeBMCs of those nodes
	bmcSet = set()
	allowedNodes = []
	for node in nodes['Components']:
		fields = node['ID'].split('n')
		bmcSet.add(fields[0])
		allowedNodes.append(node['ID'])
	bmcList = list(bmcSet)
	rfEPs = []
	start = 0
	end = len(bmcList)
	if end > MaxComponentQuery:
		end = MaxComponentQuery
	while start < len(bmcList):
		rfEpData, stat = getHSMRFEndpoints(authToken, "?type=nodebmc&id=" + '&id='.join(bmcList[start:end]))
		if stat != 0:
			err = {
				'Message': 'HSM RedfishEndpoints returned non-zero. %s' % rfEpData,
				'Severity': 'Error'
			}
			report['Errors'].append(err)
			printReport(report)
			return 1
		rfEPs.extend(rfEpData['RedfishEndpoints'])
		start = end
		end = end + MaxComponentQuery
		if end > len(bmcList):
			end = len(bmcList)

	discoveryErrList = []
	slotSet = set()
	for rfEp in rfEPs:
		if rfEp['Enabled']:
			fields = rfEp['ID'].split('b')
			slotSet.add(fields[0])
			if not rfEp['DiscoveryInfo']['LastDiscoveryStatus'] == "DiscoverOK":
				discoveryErrList.append(rfEp['ID'])
	if len(discoveryErrList) != 0:
		err = {
			'Message': 'Discovery errors detected.',
			'Severity': 'Error',
			'IDs': discoveryErrList
		}
		if not ignoreDiscoveryErrors:
			report['Errors'].append(err)
			printReport(report)
			return 1
		# Still report even if we're ignoring discovery errors
		err['Severity'] = 'Warning'
		report['Errors'].append(err)

	nodeList = []
	mismatchList = []
	for slot in slotSet:
		# Retrieve FRU information for all nodes in the slot so we can just compare nodes we expect to be the same.
		hwInv, stat = getHSMHWInv(authToken, slot, "?type=node&children=false")
		if stat != 0:
			err = {
				'Message': 'HSM Hardware Inventory returned non-zero. %s' % hwInv,
				'Severity': 'Error'
			}
			report['Errors'].append(err)
			printReport(report)
			return 1

		nodeType = ""
		mismatch = False
		node0Type = ""
		tempNodeList = []
		# Make sure all node types match. If they don't, try to determine which
		# one is correct using the type of b0n0 or b1n0 since one of them should
		# always be there.
		for nodeFRU in hwInv['Nodes']:
			newNodeType = nodeFRU['PopulatedFRU']['NodeFRUInfo']['Model']
			if nodeFRU['ID'].endswith("b0n0"):
				node0Type = nodeFRU['PopulatedFRU']['NodeFRUInfo']['Model']
			if nodeFRU['ID'].endswith("b1n0") and node0Type == "":
				# River multi-node compute modules start at b1 instead of b0.
				node0Type = nodeFRU['PopulatedFRU']['NodeFRUInfo']['Model']
			if nodeType == "":
				nodeType = newNodeType
			if not nodeType == newNodeType:
				mismatch = True
			tempNodeList.append(nodeFRU['ID'])
		if mismatch:
			for nodeFRU in hwInv['Nodes']:
				if not nodeFRU['ID'] in allowedNodes:
					continue
				newNodeType = nodeFRU['PopulatedFRU']['NodeFRUInfo']['Model']
				if node0Type == newNodeType:
					nodeList.append(nodeFRU['ID'])
				else:
					mismatchList.append(nodeFRU['ID'])
		else:
			for xname in tempNodeList:
				if xname in allowedNodes:
					nodeList.append(xname)
	if len(mismatchList) > 0:
		err = {
			'Message': 'Node does not match the hardware type of other nodes in the same slot and will be deleted.',
			'Severity': 'Info',
			'IDs': mismatchList
		}
		report['Errors'].append(err)


	# Retrieve new list of nodes based off of our filtered list of nodes
	compFilter = {
		'ComponentIDs': nodeList,
		'type': ['Node'],
		'role': ['Compute']
	}
	nodesFiltered, stat = getHSMCompQuery(authToken, compFilter)
	if stat != 0:
		err = {
			'Message': 'HSM Components query returned non-zero. %s' % nodesFiltered,
			'Severity': 'Error'
		}
		report['Errors'].append(err)
		printReport(report)
		return 1

	workingNodeList = []
	for node in nodesFiltered['Components']:
		workingNodeList.append(node['ID'])

	# Get the nodes in our NID range and make sure there isn't anything we're not allowed to touch.
	nodesRange, stat = getHSMComps(authToken, "?nid_start=%d&nid_end=%d" % (startingNID, startingNID+len(workingNodeList)-1))
	if stat != 0:
		err = {
			'Message': 'HSM Components returned non-zero. %s' % nodesRange,
			'Severity': 'Error'
		}
		report['Errors'].append(err)
		printReport(report)
		return 1
	nidErrList = []
	for node in nodesRange['Components']:
		if node['ID'] not in allowedNodes:
			nidErrList.append(node['ID'])
	if len(nidErrList) != 0:
		err = {
			'Message': 'There is an unexpected node NID in the requested NID range, %d-%d' % (startingNID, startingNID+len(workingNodeList)-1),
			'Severity': 'Error',
			'IDs': nidErrList
		}
		report['Errors'].append(err)
		printReport(report)
		return 1

	# Look for entries in SLS with conflicting NIDs. We'll delete these later.
	slsDeleteList = []
	for nid in range(startingNID, startingNID+len(workingNodeList)):
		slsNodes, stat = getSLSComps(authToken, "?extra_properties.NID=%d" % nid)
		if stat != 0:
			err = {
				'Message': 'SLS hardware search returned non-zero. %s' % slsNodes,
				'Severity': 'Error'
			}
			report['Errors'].append(err)
			printReport(report)
			return 1
		if slsNodes is None:
			continue
		for slsNode in slsNodes:
			if slsNode['Xname'] not in allowedNodes:
				slsDeleteList.append(slsNode['Xname'])

	report['NodesRemovedFromSLS'] = slsDeleteList

	# Look for entries in our "allowed" list that aren't in our working list.
	# These entries are leftovers from removed hardware. We'll delete these later.
	hsmDeleteList = []
	for id in allowedNodes:
		if id not in workingNodeList:
			hsmDeleteList.append(id)

	nodesFiltered['Components'].sort(key = compSort)
	currentNID = startingNID
	chassisClass = ""
	myChassis = ""
	newNIDList = []
	newSLSList = []
	for node in nodesFiltered['Components']:
		fields = node['ID'].split('s')
		if chassisClass == "" or myChassis != fields[0]:
			myChassis = fields[0]
			chassisClass, stat = getChassisClass(authToken, myChassis)
			if stat != 0:
				err = {
					'Message': 'Failed to get Chassis class from SLS.',
					'Severity': 'Error'
				}
				report['Errors'].append(err)
				printReport(report)
				return 1

		newNID = node.copy()
		newNID['NID'] = currentNID
		# The class designation for nodes that are in HSM but not SLS may be
		# incorrect. We'll want to update them too.
		newNID['Class'] = chassisClass

		newSLS = {
			'Xname': node['ID'],
			'Class': chassisClass,
			'ExtraProperties': {
				'Aliases': ["nid%06d" % currentNID],
				'NID': currentNID,
				'Role': "Compute"
			}
		}
		currentNID += 1
		newNIDList.append(newNID)
		newSLSList.append(newSLS)

	# Add the plan to the report
	for i in range(len(nodesFiltered['Components'])):
		node = {
			'ID': nodesFiltered['Components'][i]['ID'],
			'OldNID': nodesFiltered['Components'][i]['NID'],
			'NewNID': newNIDList[i]['NID']
		}
		report['HSMChanges'].append(node)
	report['SLSEntries'] = newSLSList

	if dryrun:
		printReport(report)
		return 0

	# Delete conflicting SLS entries
	for xname in slsDeleteList:
		resp, stat = deleteSLSComp(authToken, xname)
		if stat != 0:
			err = {
				'Message': 'Failed to delete entry from SLS. %s' % resp,
				'Severity': 'Warning',
				'IDs': [xname]
			}
			report['Errors'].append(err)

	failedEthDels = {
		'Message': 'Failed to delete ethernet interface data entries from HSM for dead nodes',
		'Severity': 'Warning',
		'IDs': []
	}

	# Cleanup dead HSM entries
	for xname in hsmDeleteList:
		resp, stat = deleteHSMComp(authToken, xname)
		if stat != 0:
			err = {
				'Message': 'Failed to delete component data from HSM. %s' % resp,
				'Severity': 'Warning',
				'IDs': [xname]
			}
			report['Errors'].append(err)
			continue
		resp, stat = deleteHSMCompEP(authToken, xname)
		if stat != 0:
			err = {
				'Message': 'Failed to delete component endpoint data from HSM. %s' % resp,
				'Severity': 'Warning',
				'IDs': [xname]
			}
			report['Errors'].append(err)
			continue
		resp, stat = deleteHSMHwLoc(authToken, xname)
		if stat != 0:
			err = {
				'Message': 'Failed to delete hardware locational data from HSM. %s' % resp,
				'Severity': 'Warning',
				'IDs': [xname]
			}
			report['Errors'].append(err)
			continue
		compEthList, stat = getHSMEth(authToken, "?ComponentID=" + xname)
		if stat != 0:
			err = {
				'Message': 'Failed to get ethernet interface data from HSM. %s' % compEthList,
				'Severity': 'Warning',
				'IDs': [xname]
			}
			report['Errors'].append(err)
			continue
		for compEth in compEthList:
			resp, stat = deleteHSMEth(authToken, compEth['ID'])
			if stat != 0:
				err = {
					'Message': 'Failed to delete ethernet interface data from HSM. %s' % resp,
					'Severity': 'Warning',
					'IDs': [compEth['ID']]
				}
				report['Errors'].append(err)
				continue

	# Update SLS entries
	for entry in newSLSList:
		resp, stat = putSLSComp(authToken, entry)
		if stat != 0:
			err = {
				'Message': 'Failed to create/update entry in SLS. %s' % resp,
				'Severity': 'Error',
				'IDs': [entry['Xname']]
			}
			report['Errors'].append(err)
			printReport(report)
			return 1

	# Update HSM NIDs
	resp, stat = patchHSMNIDs(authToken, newNIDList)
	if stat != 0:
		err = {
			'Message': 'Failed to update NIDs in HSM. %s' % resp,
			'Severity': 'Error',
			'IDs': []
		}
		for node in newNIDList:
			err['IDs'].append(node['ID'])
		report['Errors'].append(err)
		printReport(report)
		return 1

	# Only updates Class because POST /State/Components doesn't check for changes in NID to apply it.
	resp, stat = postHSMComps(authToken, newNIDList)
	if stat != 0:
		print("HSM POST /State/Components returned non-zero.")
		err = {
			'Message': 'Failed to update HSM component data. %s' % resp,
			'Severity': 'Error',
			'IDs': []
		}
		for node in newNIDList:
			err['IDs'].append(node['ID'])
		report['Errors'].append(err)
		printReport(report)
		return 1

	printReport(report)
	return 0

if __name__ == "__main__":
	ret = main()
	sys.exit(ret)
