while true;

do
    
    
    tail /var/log/warp/cli.log;
    
    
    tail /var/log/warp/svc-err.log;
    
    tail /var/log/warp/cli-err.log;
    
    tail /var/log/warp/svc.log;
    warp-cli --accept-tos --json --verbose status;
    sleep 1;
    
    
done;