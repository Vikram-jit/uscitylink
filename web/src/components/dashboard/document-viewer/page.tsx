"use client"
import React from 'react'
import DocViewer from "react-doc-viewer";

export default function DocumentViewer() {

  return (
    <DocViewer documents={[{uri:"https://morth.nic.in/sites/default/files/dd12-13_0.pdf"}]} />
  )
}
