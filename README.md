# Lab 2

### Run:

Make log directory if not exists

`./compile.sh`

Start on given port

`./start.sh <PORT_NUMBER>`

e.g.

`./start.sh 2000`

### Sample input: 

```bash
echo -e "HELO test\n" | nc localhost 2000
echo -e "HELO Other\n" | nc localhost 2000
echo -e "Foo Bar\n" | nc localhost 2000
echo -e "KILL_SERVICE\n" | nc localhost 2000
```

