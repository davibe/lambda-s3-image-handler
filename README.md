
README
======

A node-based package that implements an Amazon Lambda handler for scaling images on s3.

When an image is added to the s3 bucket
- check if it's original based on the filename
- if it is
  - calculates variants (scaled image names)
  - checks if the variants are present
  - if they are not it scales and saves the variants

When an image is removed from the s3 bucket
- checks if it's an original based on the filename
- if it is
  - calculates variants (scaled image names)
  - removes them from s3 if present

There are a bunch of other scripts doing something similar.
So, what's different here ?

- All based on simplistic file-naming rules (see `src/rules.coffee`)
- Also cares about deleting the files
- Written in coffee + generators, compiled to js, runs on lambda (old node.js) thx to babel


### Structure

- `src/*coffee`: source files
- `dist/`: where source files are compiled to js
- `index.js`: the amazon lambda entry point.

Note:
`index.js` also includes babel on-the-fly transpiler and polyfills because
Amazon Lambda uses an old version of node that does not support advanced features we use.


### Building `lambda.zip`

    cd [this project]
    npm install .
    npm run build-lambda
    
The file is ready for upload to AWS console. See `package.json` for more details