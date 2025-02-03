"use client"

import { useGetAllTrainingQuery } from "@/redux/TrainingApiSlice";
import { CircularProgress, Typography } from "@mui/material"
import React from "react";
import { TrainingTable } from "./trainingTable";

export default function Training(){
    
  // const {search} = useSelector((state:any)=>state)
  // const value = useDebounce(search.search,200)
  const [page, setPage] = React.useState(1);

  const { data, isLoading } = useGetAllTrainingQuery({page:page});

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <TrainingTable count={data?.data?.pagination?.currentPage} page={page} rows={data?.data?.data} setPage={setPage} pagination={data?.data?.pagination} />
      )}
    </>
  );


}