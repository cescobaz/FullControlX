# FullControl X - Driver

`fcxd` is a cross-platform C/Objective-C application to simulate keyboard and mouse device.  

Current OS support:

* Linux 90%
* MacOS 90%
* Windows 0%

## Usage

`fcxd` exposes a JSON messages I/O interface. Interaction is via standard I/O.  
Just launch the executable and write to the standard input.

### Request

The app accepts messages in JSON array format as follow:  

```
[ <message_id>, "function_name", <arg_1>, <arg_2>, ... ]
```

* You can concat multiple messages without a separator.
* `<message_id>` can be of type of your choice, I suggest to use a number.
* A complete list of `function names` is available at [src/fcx_request_handler.c](src/fcx_request_handler.c) line 11.
* For the arguments you have to read the code, there are no documentation yet.

### Response

Response is given via standard out, in a JSON object with the request included. Each response ends with a NULL byte (0x0000):
```
{ "request": [...], "response": { ... } }\0
```

Info, error and debug messages are available from standard error output.

### Warning

* Some parameters are encoded like the keyboard layout (US).
* This app could be used as stand alone app, but the interface is not stable yet and it is going to change.

## Build

### Requirements

* CMake [https://cmake.org/](https://cmake.org/)
* json-c lib [https://github.com/json-c/json-c](https://github.com/json-c/json-c)
* C Unit (for testing) [https://cunit.sourceforge.io/](https://cunit.sourceforge.io/)
* For MacOS: Minimum deployment target: 10.11

### Build with CMake

```bash
mkdir _build
cd _build
cmake ..
cmake --build .
```

or use the script [build.sh](build.sh).

Then run `_build/FullControlX`.

### Build - Windows

Tips:
- disable test because of cunit
- use MinGW
- use json-c static

#### Using MinGW

```sh
mkdir _build
cd _build
cmake -G "MinGW Makefiles" -DCMAKE_PREFIX_PATH=/Program\ files\ \(x86\)/json-c/lib/cmake
```

## Where are framework headers?

```
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks
```

