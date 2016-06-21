fs = require 'fs'
Path = require 'path'
mkdirp = require 'mkdirp'

sourceFile = process.argv[2]
targetFolder = process.argv[3]

unless sourceFile? and sourceFile.length > 0
	console.error 'You must specify a source file.'
	process.exit 1

unless targetFolder? and targetFolder.length > 0
	console.error 'You must specify a target folder.'
	process.exit 1

console.log 'Extracting file:',sourceFile
console.log 'Extracting to:',targetFolder

DECODE_MASK = 0x96
CUB_MAGIC_HEADER = new Buffer [0x63,0x75,0x62,0x00,0x31,0x2E,0x30,0x00]
ENTRY_PATH_LENGTH = 0x100
LONG_LENGTH = 4
ENTRY_TOTAL_LENGTH = ENTRY_PATH_LENGTH + LONG_LENGTH*2
WRITE_BUFFER_LENGTH = 1024
PATH_ENCODING = 'utf8'

decodeBuff = (buff,length)->
	for i in [0..(length-1)]
		buff[i] = buff[i]^DECODE_MASK
	buff

readBytes = (fd,offset,length)->
	buff = new Buffer length

	remainingBytes = length
	totalRead = 0

	while totalRead < length
		bytesRead = fs.readSync fd,buff,totalRead,remainingBytes,offset+totalRead
		totalRead += bytesRead
		remainingBytes -= bytesRead

	decodeBuff buff,length

readLong = (buffer,offset=0)->
	buffer.readUInt32LE offset

readEntry = (fd,index)->
	startOffset = CUB_MAGIC_HEADER.length + LONG_LENGTH + ENTRY_PATH_LENGTH +
	index*ENTRY_TOTAL_LENGTH

	readBuffer = readBytes fd,startOffset,ENTRY_TOTAL_LENGTH

	path = null

	for buffIndex in [0..(ENTRY_PATH_LENGTH-1)]
		if readBuffer[buffIndex] is 0
			path = readBuffer.toString PATH_ENCODING,0,buffIndex
			break

	path ?= readBuffer.toString PATH_ENCODING,0,ENTRY_PATH_LENGTH # if we didn't find 0 then path is full length.

	result =
		path: path

	result.offset = readLong readBuffer,ENTRY_PATH_LENGTH
	result.length = readLong readBuffer,(ENTRY_PATH_LENGTH+LONG_LENGTH)

	result

writeEntry = (fd,entry)->
	console.log 'Processing entry:',entry.path
	outputFile = fs.openSync Path.join(targetFolder,entry.path),'w'

	readOffset = entry.offset
	remainingBytesToRead = entry.length

	buff = new Buffer WRITE_BUFFER_LENGTH

	while remainingBytesToRead > 0
		bytesRead = fs.readSync fd,buff,0,Math.min(WRITE_BUFFER_LENGTH,remainingBytesToRead),readOffset
		readOffset += bytesRead
		decodeBuff buff,bytesRead
		fs.writeSync outputFile,buff,0,bytesRead
		remainingBytesToRead -= bytesRead

	fs.closeSync outputFile

fd = fs.openSync sourceFile,'r'

header = readBytes(fd,0,CUB_MAGIC_HEADER.length)

unless CUB_MAGIC_HEADER.equals header
	console.error 'Source is not a cub file.'
	process.exit 1

entryCount = readLong readBytes(fd,CUB_MAGIC_HEADER.length,LONG_LENGTH)

console.log 'Entries found:',entryCount

entries = []

for i in [0..(entryCount-1)]
	entries.push readEntry(fd,i,)

mkdirp.sync targetFolder

for entry in entries
	writeEntry fd,entry

fs.closeSync fd
