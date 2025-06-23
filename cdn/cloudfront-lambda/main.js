const AWS = require("aws-sdk");

const cloudfront = new AWS.CloudFront();

const DistributionId = process.env.DISTRIBUTION_ID || "";

exports.handler = async function () {
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
  await cloudfront.createInvalidation(params).promise();
};
