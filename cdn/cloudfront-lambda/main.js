const AWS = require("aws-sdk");

const cloudfront = new AWS.CloudFront();

const DistributionId = process.env.DISTRIBUTION_ID || "";

exports.handler = async function (event) {
  const params = {
    DistributionId,
    InvalidationBatch: {
      CallerReference: new Date().toISOString(),
      Paths: {
        Quantity: 1,
        Items: ["/*"],
      },
    },
  };
  console.log(params);
  const res = await cloudfront.createInvalidation(params).promise();
  console.log(res);
};
