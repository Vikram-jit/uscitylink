"use client"

import { useGetAllTrainingQuery, useGetAssginDriverQuery } from "@/redux/TrainingApiSlice";
import { CircularProgress, Typography } from "@mui/material"
import React from "react";
import { TrainingTable } from "./trainingTable";
import { AssginDriverTable } from "./assginDriverTable";

export default function AssginDriver({id}:{id:string}){
    
  // const {search} = useSelector((state:any)=>state)
  // const value = useDebounce(search.search,200)
  const [page, setPage] = React.useState(1);

  const { data, isLoading } = useGetAssginDriverQuery({id:id, page:page});

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <AssginDriverTable count={data?.data?.pagination?.currentPage} page={page} rows={data?.data.data.drivers} setPage={setPage} pagination={data?.data?.pagination} />
      )}
    </>
  );


}