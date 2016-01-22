
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


### Using on AWS Lambda

While the script can work with both original images and variants (scaled versions)
in the same directory it's recommended that you use a subfolder for the originals

i.e. `originals/`

This way you can attach the lambda handler to that specific path and it will not 
get triggered by events of generated variant files.

If you don't do this the lambda handler will be launched also for the created/deleted
variants. The current strategy is to do nothing in that case but you will still pay
the time consumed by the handler checking wether the file it's an original or not
(with a minimum of 100ms).
