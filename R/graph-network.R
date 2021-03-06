id_sn_index <- function(x) {
  id <- character()
  sn <- character()
  if ("mentions_user_id" %in% names(x)) {
    id <- unroll_users(x$mentions_user_id)
    sn <- unroll_users(x$mentions_screen_name)
    x$mentions_user_id <- NULL
    x$mentions_screen_name <- NULL
  }
  id_vars <- grep("user_id$", names(x), value = TRUE)
  sn_vars <- grep("screen_name$", names(x), value = TRUE)
  id <- c(id, unlist(x[id_vars], use.names = FALSE))
  sn <- c(sn, unlist(x[sn_vars], use.names = FALSE))
  kp <- !duplicated(id) & !is.na(id)
  list(id = id[kp], sn = sn[kp])
}


id_sn_join <- function(x, ref) {
  m <- match(x, ref$id)
  ref$sn[m]
}

prep_from_to <- function(x, from, to) {
  if (is.list(x[[to]])) {
    unroll_connections(x[[from]], x[[to]])
  } else {
    x <- x[c(from, to)]
    names(x) <- c("from", "to")
    x <- x[!is.na(x[[2]]), ]
    x
  }
}

#' Network data
#'
#' Convert Twitter data into a network-friendly data frame
#'
#' @param .x Data frame returned by rtweet function
#' @param .e Type of edge/link–i.e., "mention", "retweet", "quote", "reply"
#' @return A from/to data edge data frame
#' @details This function returns a data frame that can easily be converted to
#'   various network classes. For direct conversion to a network object, see
#'  \code{\link{network_graph}}.
#' @seealso network_graph
#' @export
network_data <- function(.x, .e = NULL) {
  if (!is.null(.e)) {
    .e <- sub("d$|s$", "", .e)
    vars <- c("user_id", "screen_name", switch(.e,
      mention = c("mentions_user_id", "mentions_screen_name"),
      retweet = c("retweet_user_id", "retweet_screen_name"),
      reply = c("reply_to_user_id", "reply_to_screen_name"),
      quote = c("quoted_user_id", "quoted_screen_name")))
    .x <- .x[, vars]
  }
  idsn <- id_sn_index(.x)
  v <- names(.x)
  .x <- prep_from_to(.x, v[1], v[3])
  attr(.x, "idsn") <- idsn
  .x
}

#' Network graph
#'
#' Convert Twitter data into network graph object (igraph)
#'
#' @param .x Data frame returned by rtweet function
#' @param .e Type of edge/link–i.e., "mention", "retweet", "quote", "reply"
#' @return An igraph object
#' @details This function requires previous installation of the igraph package.
#'   To return a network-friendly data frame, see \code{\link{network_data}}
#' @seealso network_data
#' @export
network_graph <- function(.x, .e = NULL) {
  if (!requireNamespace("igraph", quietly = TRUE)) {
    stop(
      "Please install the {igraph} package to use this function",
      call. = FALSE
    )
  }
  .x <- network_data(.x, .e)
  idsn <- attr(.x, "idsn")
  g <- igraph::make_empty_graph(n = 0, directed = TRUE)
  g <- igraph::add_vertices(g, length(idsn$id),
    attr = list(user_id = idsn$id, screen_name = idsn$sn))
  edges <- rbind(match(.x[[1]], idsn$id), match(.x[[2]], idsn$id))
  if (!is.null(.e)) {
    g <- igraph::add_edges(g, edges, attr = list(type = rep(.e, nrow(.x))))
  }
  g
}

# user_vars <- c("user_id", "screen_name", "name", "location", "description",
#   "url", "protected", "followers_count", "friends_count", "listed_count",
#   "statuses_count", "favourites_count", "account_created_at", "verified",
#   "profile_url", "profile_expanded_url", "account_lang",
#   "profile_banner_url", "profile_background_url", "profile_image_url")
