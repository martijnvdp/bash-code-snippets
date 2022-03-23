#!/usr/bin/env -S awk -f
# https://gist.github.com/yermulnik/7e0cf991962680d406692e1db1b551e6
# Tested with GNU Awk 5.0.1, API: 2.0 (GNU MPFR 4.0.2, GNU MP 6.2.0)
# Usage: cat variables.tf | awk -f /path/to/tf_vars_sort.awk | tee sorted_variables.tf
# No licensing; yermulnik@gmail.com, 2021
{
	# drop blank lines at the beginning of file
	if (!resource_type && length($0) == 0) next

	# pick only known and easily parsable (for our goal) TF block names
	# https://github.com/hashicorp/terraform/blob/main/internal/configs/parser_config.go#L55-L163
	switch ($0) {
		case /^[[:space:]]*(locals|moved|provider|terraform)[[:space:]]+{/:
			resource_type = $1
			resource_ident = resource_type "|" block_counter++
		case /^[[:space:]]*(data|resource)[[:space:]]+.+{/:
			resource_type = $1
			resource_subtype = $2
			resource_name = $3
			resource_ident = resource_type "|" resource_subtype "|" resource_name
		case /^[[:space:]]*(module|output|variable)[[:space:]]+.+{/:
			resource_type = $1
			resource_name = $2
			resource_ident = resource_type "|" resource_name
	}
	arr[resource_ident] = arr[resource_ident] ? arr[resource_ident] RS $0 : $0
} END {
	# case-insensitive string operations in this block
	IGNORECASE = 1
	# sort by `resource_ident` which is a key in our case
	asort(arr)

	# blank-lines-fix each block
	for (item in arr) {
		split(arr[item],new_arr,RS)

		# remove blank lines at the end of block
		for (i = length(new_arr); i >= 0; i--) {
			if (length(new_arr[i]) == 0) delete new_arr[i]
		}

		# add blank line at the end of the resource definition block
		# so that blocks are delimited with a blank like to align with TF code style
		counter=0
		for (line in new_arr) {
			counter++
			res = res RS new_arr[line]
			if (counter == length(new_arr) && new_arr[line] ~ /}[[:space:]]*$/) res = res RS
		}
	}

	# ensure there are no extra blank lines
	split(res,final_arr,RS)
	counter=0
	for (line in final_arr) {
		counter++
		# strip blank lines at the beginning and end of data
		if ( \
			(counter == 1 || counter == length(final_arr)) \
			&& length(final_arr[line]) == 0 \
		) continue
		print final_arr[line]
	}
}