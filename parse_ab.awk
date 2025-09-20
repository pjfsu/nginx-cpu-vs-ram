/Requests per second/ { rps=$4 }
/^Time per request:/ && !seen++ { avg=$4 }
/  95%/ { p95=$2 }
END {
	printf "%-7s %12s requests/sec\t%8s ms average response time\t%4s ms 95th percentile response time\n",
	target, rps, avg, p95
}
