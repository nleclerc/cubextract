# cubextract

## Goal
This is a tool to extract resources from a `cub` resource file.
Those are found in some games.

## Installation
* Install Node.js.
* run `npm install`

## Usage
`bin/cubextract <SOURCE_FILE> <DESTINATION_FOLDER>`

## Note on the CUB format
* Each byte is "encoded" by XORing it with `0x96`.
* File starts with a specific header (`CUB_1.0_` underscores are actually bytes with a 0 value)
* Followed by the number of entries (4 bytes, little endian)
* Followed by the actual entries, made up of:
  * a 256 byte long path (padded with trailing 0s if needed)
  * a 4 byte offset (little endian)
  * a 4 byte length (little endian)
* Then you have all the concatenated file contents.

## License
This project is available under [GPL v2.0](http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt) or later.
