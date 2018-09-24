open Types
open Aws
type input = unit
type output = AccountAttributesMessage.t
type error = Errors.t
let service = "rds" 
let to_http req =
  let uri =
    Uri.add_query_params (Uri.of_string "https://rds.amazonaws.com")
      [("Version", ["2014-10-31"]);
      ("Action", ["DescribeAccountAttributes"])]
     in
  (`POST, uri, []) 
let of_http body =
  try
    let xml = Ezxmlm.from_string body  in
    let resp =
      Util.option_bind
        (Xml.member "DescribeAccountAttributesResponse" (snd xml))
        (Xml.member "DescribeAccountAttributesResult")
       in
    try
      Util.or_error (Util.option_bind resp AccountAttributesMessage.parse)
        (let open Error in
           BadResponse
             {
               body;
               message =
                 "Could not find well formed AccountAttributesMessage."
             })
    with
    | Xml.RequiredFieldMissing msg ->
        let open Error in
          `Error
            (BadResponse
               {
                 body;
                 message =
                   ("Error parsing AccountAttributesMessage - missing field in body or children: "
                      ^ msg)
               })
  with
  | Failure msg ->
      `Error
        (let open Error in
           BadResponse { body; message = ("Error parsing xml: " ^ msg) })
  
let parse_error code err =
  let errors = [] @ Errors.common  in
  match Errors.of_string err with
  | Some var ->
      if
        (List.mem var errors) &&
          ((match Errors.to_http_code var with
            | Some var -> var = code
            | None  -> true))
      then Some var
      else None
  | None  -> None 