spark_worker_connect <- function(sessionId) {
  gatewayPort <- "8880"
  gatewayAddress <- "localhost"

  log("is connecting to backend using port ", gatewayPort)

  gatewayInfo <- spark_connect_gateway(gatewayAddress,
                                       gatewayPort,
                                       sessionId,
                                       config = config,
                                       isStarting = TRUE)

  log("is connected to backend")
  log("is connecting to backend session")

  tryCatch({
    # set timeout for socket connection
    timeout <- spark_config_value(config, "sparklyr.backend.timeout", 30 * 24 * 60 * 60)
    backend <- socketConnection(host = "localhost",
                                port = gatewayInfo$backendPort,
                                server = FALSE,
                                blocking = TRUE,
                                open = "wb",
                                timeout = timeout)
  }, error = function(err) {
    close(gatewayInfo$gateway)

    abort_shell(
      paste("Failed to open connection to backend:", err$message),
      spark_submit_path,
      shell_args,
      output_file,
      error_file
    )
  })

  log("is connected to backend session")

  sc <- structure(class = c("spark_worker_connection"), list(
    # spark_connection
    master = "",
    method = "shell",
    app_name = NULL,
    config = NULL,
    # spark_shell_connection
    spark_home = NULL,
    backend = backend,
    monitor = gatewayInfo$gateway,
    output_file = NULL
  ))

  log("created connection")

  sc
}

jobj_subclass.shell_backend <- function(con) {
  "worker_jobj"
}
