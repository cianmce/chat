# Lab 4

### Run:

Make log directory if not exists

`./compile.sh`

Start on given port

`./start.sh <PORT_NUMBER>`

e.g.

`./start.sh 2000`

### Note

The test says KILL_SERVICE doesn't stop the server, but it does and it close the program


### Sample input: 

```bash
echo -e "HELO test\n" | nc localhost 2000
echo -e "HELO Other\n" | nc localhost 2000
echo -e "Foo Bar\n" | nc localhost 2000
echo -e "KILL_SERVICE\n" | nc localhost 2000
```

Error with KILL_SERVICE grading.
Probably cause being run on free online server. It does successfully close

