-- Alpha topology sampled from the supplied ImageMagick implementation.
local bytes = require("@dream/bytes")
local P = {
    ["enchant_frame_spiral"] = "eNqNlbmVhDAQRMtaLFLBGk8JEQIbB7koHYXSOyBmVtXXUzk4/5WaPgHSTzmbXALaWRbE2qo8YP9K3QLy1R5SBrWXQ67VIW/vVaNFYhVG98C0ax/RX8l1GNdE+0ysKuZVZtSzUafYepdA5nQVpU2y7d0DMqstjha6MHUxyIeEgYtvB489DQrv/f53mrwwYOJX/192QvBYUDg5CpmBv036JC+DH/ATcvaTZJsYQ7wSMNtUbcOsUN2QZDvoh9hWFtgeC8KVdNqYrdjydNNcJPOmMubO8dA+ao45Ynp39K353qEQ1nSfcR2+exIZCt7AB3LXg/Y650cVbFf3Qt2PsezF3iHDddTeofu+mSmAf9/63WQYfDf/ABD+YqA=",
    ["enchant_frame_spiral_large"] = "eNqVlcEVhCAMROe0nmyFkzcasgS3DntJOykluy4qJEBw5yLKfzFvAgmg9Io7SxLvcUJfgUSLQodcWGrx0iBnkrZotmiUvqJGV/G0lujb7kK/bk5U4F6k5ZpzBdywOedZo2ihIskNUix61v1KoAH08KMoXLFt8fcMwAKwizPFAELpUYFYb4Sm9Klm0fBNDItEtdLepQqMnhUsUrHOKToDo8/AHhQPlhqWP2B5kMUYga4Y+j+8dv0s1S4/hXHUbWQ+bjYOLcqRpoEPJQsaRM0sIZh00c0h/O4bGslVpvF1jy9Vf8ifltQfnlSZzr7zRLPXe/XZi173hXoUHXhrOptfNrevo7zeqz8vSvuiP4eKW1XPITPfbrQ539TcvEzQc/MD65iScA==",
}
local M = {}
function M.get(name)
    local p=P[name]
    if not p then error("unknown spiral template "..name,2) end
    return { width=44, height=44, data=bytes.inflate(bytes.fromBase64(p), { maxSize=1936 }) }
end
return M
