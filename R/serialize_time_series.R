#' @title Serialize time series 
#' @description Provides numerous functions to serialize all time series

BASE_PATH <- 'inst/extdata/'
EXTENSION <- '.csv'

#' Writes a dataframe to csv
#'
#' @param dataframe_name the character name of a data frame
#' @param dataframe the data.frame itself
#' @param base_path the character path to a directory with trailing slash
#' @param extension the character suffix for the serialized data frame
#' @return the name of the file
write_out <- function(dataframe_name, dataframe, base_path, extension){
	file_name <- paste(base_path, dataframe_name, extension, sep = "")
	write.csv(dataframe, file_name, quote = TRUE, na = "NULL")
	return(file_name);
}

#' Get all data frame names
#'
#' @return a list of string data frame names
#' @export
get_time_series_data_frame_names <- function(){
	return(list(
		'aflow',
		'aloads',
		'dflow',
		'discqw',
		'mflow',
		'mloads',
		'pest21day',
		'pest60day',
		'pestsamp',
		'pestsites',
		'pestweightave'
	))
}

#' Get all data frames and their names
#'
#' @return a list whose keys are strings and whose values are the data frames
#' @export
get_time_series_data_frames_and_names <- function() {
	all_time_series <- list()
	for (time_series_name in get_time_series_data_frame_names()) {
		all_time_series[[time_series_name]] <- get(time_series_name)
	}
	return(all_time_series)
}

#' Execute a function on each named data frame
#'
#' given a list of dataframe names mapped to data frames, iterate
#' through every one, passing the dataframe name and dataframe to
#' the specified function. The specified function must accept two
#' parameters. The first is a character name. The second is a 
#' data frame.
#' @param data_frames a vector of data.frames
#' @param fn a function that will be passed a name and a data frame
#' @export
for_each_data_frame <- function(data_frames, fn) {
	for (data_frame_name in names(data_frames)) {
		data_frame <- data_frames[[data_frame_name]]
		fn(data_frame_name, data_frame)
	}
}

#' Serializes time series with default options
#' 
#' This is called to execute the default behavior on Job Servers. Tests and customizations should use
#' serialize_specific_time_series
#' @export
serialize_time_series <- function(){
	serialize_specific_time_series(get_time_series_data_frames_and_names(), BASE_PATH, EXTENSION)
}

#' Serialize the specified time series
#' 
#' Serializes the specified time series to csv at the given base path with the given file extension.
#' file names in the destination dir are the concatenation of the data frame's name, a dot, and the extension
#' This function briefly modifies the global scipen option. It restores the previous value after it has
#' accomplished its main tasks.
#' 
#' @param time_series_data_frames_and_names a list whose keys are strings and whose values are data frames
#' @param base_path a string path to the directory where data frames should be serialized. Must include trailing slash.
#' @param extension a string file extension
#' @return list of character file names
#' @export
serialize_specific_time_series <- function(time_series_data_frames_and_names, base_path, extension){
	old_scipen_value <- options()$scipen
	files_written <- list()
	tryCatch({
		options(scipen = 999)
		for_each_data_frame(time_series_data_frames_and_names, function(data_frame_name, data_frame){
			written_file <- write_out(data_frame_name, data_frame, base_path, extension)
			append(files_written, written_file)
		})
	}, 
	finally = {
		options(scipen = old_scipen_value)
	})
	return(files_written)
}

get_unique_sites_from_data_frame <- function(frame){
  unique(frame$SITE_QW_ID)
}

concatenate_unique_site_ids <- function(allIds, idsFromThisFrame){
  unique(c(idsFromThisFrame, allIds))
}

has_site_id_column <- function(frame){
  "SITE_QW_ID" %in% names(frame)
}

#' Given a list of data frames, get a list of all unique site ids.
#' Silenty ignores any data frames that do not have the expected site id column name
#' @param data_frames a list of data frames
#' @return vector of unique character site ids
#' @export
get_site_ids <- function(data_frames){
  data_frames_with_site_id_columns <- Filter(
    has_site_id_column,
    data_frames
  )
  
  sites_from_each_data_frame <- Map(
    get_unique_sites_from_data_frame,
    data_frames_with_site_id_columns
  )
  
  unique_sites <- Reduce(
    concatenate_unique_site_ids, 
    sites_from_each_data_frame,
    c()
  )
  
  return(unique_sites)
}

#' Get a list of all unique site ids across all the time series data frames
#' @return vector of unique character site ids
#' @export
get_all_site_ids <- function(){
  get_site_ids(get_time_series_data_frames_and_names())
}
